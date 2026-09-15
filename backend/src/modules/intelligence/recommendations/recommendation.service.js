const { ObjectId } = require("mongodb");
const { getDb } = require("../../../config/mongodb");
const { generateRecommendations } = require("./recommendation.engine");

function normaliseObjectMap(rows, keyField, valueField = "value") {
  return rows.reduce((map, row) => {
    const key = String(row[keyField]);
    map[key] = Number(row[valueField] || 0);
    return map;
  }, {});
}

async function getRecommendations(userId, options = {}) {
  const db = getDb();

  const limit = Number(options.limit || 5);
  const safeLimit = Number.isInteger(limit) && limit >= 1 ? Math.min(limit, 10) : 5;

  const cart = await db.collection("carts").findOne({ userId });
  const excludedItemIds = cart?.items?.map((item) => item.menuItemId) || [];

  const menuItems = await db
    .collection("menu")
    .find({ available: true })
    .toArray();

  if (!menuItems.length) {
    return [];
  }

  const menuIds = menuItems.map((item) => item._id);

  const [userOrders, userReviews, globalPopularity, ratingSummary] = await Promise.all([
    db.collection("orders").find({ userId, status: { $ne: "CANCELLED" } }).toArray(),
    db.collection("reviews").find({ userId }).toArray(),
    db.collection("orders").aggregate([
      { $match: { status: { $ne: "CANCELLED" } } },
      { $unwind: "$items" },
      { $group: { _id: "$items.menuItemId", totalQty: { $sum: "$items.quantity" } } },
    ]).toArray(),
    db.collection("reviews").aggregate([
      { $group: {
          _id: "$menuItemId",
          averageRating: { $avg: "$rating" },
          ratingCount: { $sum: 1 },
        } },
    ]).toArray(),
  ]);

  const itemQtyByUser = {};
  const categoryQtyByUser = {};
  const userCategories = new Set();
  const itemNames = new Map();

  for (const order of userOrders) {
    for (const item of order.items || []) {
      const itemId = item.menuItemId.toString();
      const menuItem = menuItems.find((candidate) => candidate._id.toString() === itemId);

      if (!menuItem) continue;

      itemQtyByUser[itemId] = (itemQtyByUser[itemId] || 0) + Number(item.quantity || 0);
      categoryQtyByUser[menuItem.category] = (categoryQtyByUser[menuItem.category] || 0) + Number(item.quantity || 0);
      userCategories.add(menuItem.category);
      itemNames.set(itemId, menuItem.name);
    }
  }

  const categoryPreference = {};
  const totalCategoryQty = Object.values(categoryQtyByUser).reduce((sum, qty) => sum + qty, 0) || 1;

  for (const [category, total] of Object.entries(categoryQtyByUser)) {
    categoryPreference[category] = total / totalCategoryQty;
  }

  const cartCategoryCounts = {};
  const categoryCoOccurrence = {};

  if (cart?.items?.length) {
    const cartMenuIds = cart.items.map((entry) => entry.menuItemId);
    const cartMenu = await db.collection("menu").find({ _id: { $in: cartMenuIds } }).toArray();

    for (const item of cartMenu) {
      cartCategoryCounts[item.category] = (cartCategoryCounts[item.category] || 0) + 1;
    }
  }

  for (const order of userOrders) {
    const categories = [...new Set(
      (order.items || [])
        .map((item) => {
          const menuItem = menuItems.find((candidate) => candidate._id.toString() === item.menuItemId.toString());
          return menuItem ? menuItem.category : null;
        })
        .filter(Boolean)
    )];

    for (const category of categories) {
      for (const otherCategory of categories) {
        if (category === otherCategory) continue;
        categoryCoOccurrence[category] = (categoryCoOccurrence[category] || {});
        categoryCoOccurrence[category][otherCategory] = (categoryCoOccurrence[category][otherCategory] || 0) + 1;
      }
    }
  }

  const cartCategoryStrength = {};
  for (const [cartCategory, count] of Object.entries(cartCategoryCounts)) {
    for (const [candidateCategory, strength] of Object.entries(categoryCoOccurrence[cartCategory] || {})) {
      cartCategoryStrength[candidateCategory] = (cartCategoryStrength[candidateCategory] || 0) + (strength * count);
    }
  }

  const globalReviewStats = await db.collection("reviews").aggregate([
    {
      $group: {
        _id: null,
        averageRating: { $avg: "$rating" },
        ratingCount: { $sum: 1 },
      },
    },
  ]).toArray();

  const globalMeanRating = Number((globalReviewStats[0]?.averageRating || 0) || 0);
  const minimumVotes = 5;

  const allRatings = {};
  for (const item of ratingSummary) {
    const itemId = item._id.toString();
    const avgRating = Number(item.averageRating || 0);
    const count = Number(item.ratingCount || 0);
    const bayesianRating = (count * avgRating + minimumVotes * globalMeanRating) / (count + minimumVotes);

    allRatings[itemId] = {
      weightedRating: bayesianRating,
      averageRating: avgRating,
      ratingCount: count,
    };
  }

  const popularityMap = normaliseObjectMap(
    globalPopularity.map((entry) => ({
      key: entry._id.toString(),
      value: entry.totalQty,
    })),
    "key",
    "value"
  );

  const userReviewsMap = {};
  for (const review of userReviews) {
    const itemId = review.menuItemId.toString();
    userReviewsMap[itemId] = Number(review.rating || 0);
  }

  const userReviewBoost = {};
  for (const [itemId, rating] of Object.entries(userReviewsMap)) {
    userReviewBoost[itemId] = rating / 5;
  }

  const allMenuItemIds = new Set(menuIds.map((id) => id.toString()));
  const preferenceMap = {};

  for (const [itemId, quantity] of Object.entries(itemQtyByUser)) {
    if (allMenuItemIds.has(itemId)) {
      preferenceMap[itemId] = quantity + (userReviewBoost[itemId] || 0);
    }
  }

  const coldStart = userOrders.length === 0 && userReviews.length === 0;

  const recommended = generateRecommendations({
    menuItems,
    excludedItemIds,
    userOrders,
    userReviews,
    userCategoryPreference: categoryPreference,
    userItemPreference: preferenceMap,
    cartCategories: cartCategoryCounts,
    cartCategoryStrength: cartCategoryStrength,
    globalPopularity: popularityMap,
    ratingSummary: allRatings,
    limit: safeLimit,
  });

  if (coldStart && recommended.length < safeLimit) {
    const fallbackItems = menuItems
      .filter((item) => !excludedItemIds.some((id) => id.toString() === item._id.toString()))
      .sort((a, b) => {
        const ratingA = allRatings[a._id.toString()]?.weightedRating || 0;
        const ratingB = allRatings[b._id.toString()]?.weightedRating || 0;
        const popularityA = popularityMap[a._id.toString()] || 0;
        const popularityB = popularityMap[b._id.toString()] || 0;
        return (ratingB + popularityB) - (ratingA + popularityA);
      });

    for (const item of fallbackItems) {
      if (!recommended.some((entry) => entry._id.toString() === item._id.toString())) {
        recommended.push({
          _id: item._id,
          name: item.name,
          price: item.price,
          category: item.category,
          available: item.available,
          imageUrl: item.imageUrl,
          recommendationScore: 0.5,
          reason: "Popular among customers",
        });
      }

      if (recommended.length >= safeLimit) break;
    }
  }

  return recommended.slice(0, safeLimit);
}

module.exports = {
  getRecommendations,
};