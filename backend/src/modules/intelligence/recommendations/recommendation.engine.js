const RECOMMENDATION_WEIGHTS = {
  personal: 0.35,
  rating: 0.2,
  popularity: 0.2,
  category: 0.15,
  cart: 0.1,
};

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

function normalizeScore(value, min, max) {
  if (max <= min) return 0;
  return (value - min) / (max - min);
}

function buildReason(signals) {
  if (signals.personal) return "Based on your previous orders";
  if (signals.rating) return "Highly rated";
  if (signals.popularity) return "Popular";
  if (signals.category) return "Matches your preferred category";
  if (signals.cart) return "Related to your cart";
  return "Popular among customers";
}

function normalizeCategoryPreference(value, maxValue) {
  if (!maxValue || maxValue <= 0) return 0;
  return clamp(Number(value || 0) / maxValue, 0, 1);
}

function diversify(items, desiredCount = 5) {
  const ranked = [...items].sort((a, b) => b.recommendationScore - a.recommendationScore);
  const selected = [];
  const categorySet = new Set();

  for (const item of ranked) {
    const category = item.category || "Other";
    if (selected.length >= desiredCount && !categorySet.has(category)) {
      continue;
    }

    selected.push(item);
    categorySet.add(category);

    if (selected.length >= desiredCount) {
      break;
    }
  }

  if (selected.length === 0) {
    return ranked;
  }

  return selected;
}

function generateRecommendations({
  menuItems,
  excludedItemIds = [],
  userOrders = [],
  userReviews = [],
  userCategoryPreference = {},
  userItemPreference = {},
  cartCategories = {},
  cartCategoryStrength = {},
  globalPopularity = {},
  ratingSummary = {},
  limit = 5,
} = {}) {
  const excluded = new Set((excludedItemIds || []).map((id) => id.toString()));
  const itemCounts = userItemPreference || {};
  const categoryPreference = userCategoryPreference || {};
  const cartCategoryMap = cartCategories || {};
  const cartStrengthMap = cartCategoryStrength || {};
  const popularityMap = globalPopularity || {};
  const ratingMap = ratingSummary || {};

  const availableItems = (menuItems || []).filter((item) => {
    if (!item.available) return false;
    return !excluded.has(item._id.toString());
  });

  if (availableItems.length === 0) return [];

  const personalValues = Object.values(itemCounts)
    .map((value) => Number(value) || 0)
    .concat(Object.values(categoryPreference).map((value) => Number(value) || 0));

  const popularityValues = Object.values(popularityMap).map((value) => Number(value) || 0);
  const ratingValues = Object.values(ratingMap).map((value) => Number(value.weightedRating) || 0);
  const categoryPreferenceValues = Object.values(categoryPreference).map((value) => Number(value) || 0);

  const personalMax = Math.max(1, ...personalValues, 0);
  const popularityMax = Math.max(1, ...popularityValues, 0);
  const ratingMax = Math.max(1, ...ratingValues, 0);
  const categoryMax = Math.max(1, ...categoryPreferenceValues, 0);

  const scored = availableItems.map((item) => {
    const itemId = item._id.toString();
    const category = item.category || "Other";

    const itemPersonal = Number(itemCounts[itemId] || 0);
    const categoryPreferenceScore = Number(categoryPreference[category] || 0);
    const personalScore = normalizeScore(itemPersonal + categoryPreferenceScore, 0, personalMax);

    const ratingInfo = ratingMap[itemId] || { weightedRating: 0 };
    const ratingScore = normalizeScore(Number(ratingInfo.weightedRating || 0), 0, ratingMax);
    const popularityScore = normalizeScore(Number(popularityMap[itemId] || 0), 0, popularityMax);
    const categoryScore = normalizeCategoryPreference(categoryPreferenceScore, categoryMax);

    const cartScore = Number((cartCategoryMap[category] || 0) + (cartStrengthMap[category] || 0));
    const cartContextScore = cartScore > 0 ? 1 : 0;

    const combinedScore =
      RECOMMENDATION_WEIGHTS.personal * personalScore +
      RECOMMENDATION_WEIGHTS.rating * ratingScore +
      RECOMMENDATION_WEIGHTS.popularity * popularityScore +
      RECOMMENDATION_WEIGHTS.category * categoryScore +
      RECOMMENDATION_WEIGHTS.cart * cartContextScore;

    const reasonSignals = {
      personal: itemPersonal > 0 || categoryPreferenceScore > 0,
      rating: ratingScore > 0.25,
      popularity: popularityScore > 0.2,
      category: categoryPreferenceScore > 0,
      cart: cartContextScore > 0,
    };

    return {
      ...item,
      recommendationScore: clamp(combinedScore, 0, 1),
      reason: buildReason(reasonSignals),
    };
  });

  const diversified = diversify(scored, Number(limit) || 5);

  return diversified
    .slice(0, Number(limit) || 5)
    .map((item) => ({
      _id: item._id,
      name: item.name,
      price: item.price,
      category: item.category,
      available: item.available,
      imageUrl: item.imageUrl,
      recommendationScore: Number(item.recommendationScore.toFixed(4)),
      reason: item.reason,
    }));
}

module.exports = {
  generateRecommendations,
  RECOMMENDATION_WEIGHTS,
};