const { ObjectId } = require("mongodb");
const { getDb } = require("../../config/mongodb");

const REVIEWS_COLLECTION = "reviews";
const MENU_COLLECTION = "menu";
const ORDERS_COLLECTION = "orders";

function getReviewsCollection() {
  return getDb().collection(REVIEWS_COLLECTION);
}

function getMenuCollection() {
  return getDb().collection(MENU_COLLECTION);
}

function getOrdersCollection() {
  return getDb().collection(ORDERS_COLLECTION);
}

function createAppError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function ensureObjectId(id, fieldName = "ID") {
  if (!id || !ObjectId.isValid(String(id))) {
    throw createAppError(`Invalid ${fieldName}`, 400);
  }

  return new ObjectId(String(id));
}

async function ensureMenuItemExists(menuItemId) {
  const objectId = ensureObjectId(menuItemId, "menuItemId");

  const menuItem = await getMenuCollection().findOne({
    _id: objectId,
  });

  if (!menuItem) {
    throw createAppError("Menu item not found", 404);
  }

  return menuItem;
}

async function ensureReviewIndexes() {
  const reviewsCollection = getReviewsCollection();

  await reviewsCollection.createIndex({ userId: 1 });
  await reviewsCollection.createIndex({ menuItemId: 1 });
  await reviewsCollection.createIndex(
    { userId: 1, menuItemId: 1 },
    { unique: true }
  );

  return true;
}

function normalizeReviewText(review) {
  if (review === undefined || review === null || review === "") {
    return "";
  }

  return String(review).trim();
}

function buildRatingSummaryFromRows(rows = []) {
  const distribution = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };

  for (const row of rows) {
    const rating = Number(row.rating || 0);

    if (rating >= 1 && rating <= 5) {
      distribution[rating] = (distribution[rating] || 0) + 1;
    }
  }

  const ratingCount = rows.length;
  const averageRating = ratingCount > 0
    ? Number(
        (
          rows.reduce((total, row) => total + Number(row.rating || 0), 0) /
          ratingCount
        ).toFixed(2)
      )
    : 0;

  return {
    averageRating,
    ratingCount,
    distribution,
  };
}

async function hasPurchasedMenuItem(userId, menuItemId) {
  const menuObjectId = ensureObjectId(menuItemId, "menuItemId");

  const order = await getOrdersCollection().findOne({
    userId,
    status: { $ne: "CANCELLED" },
    "items.menuItemId": menuObjectId,
  });

  if (!order || !Array.isArray(order.items)) {
    return false;
  }

  return order.items.some(
    (item) =>
      item.menuItemId &&
      item.menuItemId.toString() === menuObjectId.toString() &&
      Number(item.quantity || 0) > 0
  );
}

async function createReview(userId, menuItemId, rating, review) {
  if (!userId) {
    throw createAppError("User authentication is required", 401);
  }

  await ensureMenuItemExists(menuItemId);

  const purchased = await hasPurchasedMenuItem(userId, menuItemId);

  if (!purchased) {
    throw createAppError(
      "You can only review menu items you purchased in a non-cancelled order",
      403
    );
  }

  const normalizedRating = Number(rating);

  if (!Number.isInteger(normalizedRating) || normalizedRating < 1 || normalizedRating > 5) {
    throw createAppError("rating must be an integer from 1 to 5", 400);
  }

  const reviewText = normalizeReviewText(review);

  if (reviewText.length > 500) {
    throw createAppError("review must be 500 characters or fewer", 400);
  }

  const reviewDocument = {
    userId,
    menuItemId: ensureObjectId(menuItemId, "menuItemId"),
    rating: normalizedRating,
    review: reviewText,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  try {
    const result = await getReviewsCollection().insertOne(reviewDocument);

    return {
      _id: result.insertedId,
      ...reviewDocument,
    };
  } catch (error) {
    if (error.code === 11000) {
      throw createAppError(
        "You have already reviewed this menu item",
        409
      );
    }

    throw error;
  }
}

async function getReviewsForMenuItem(menuItemId) {
  const objectId = ensureObjectId(menuItemId, "menuItemId");

  await ensureMenuItemExists(menuItemId);

  return getReviewsCollection()
    .find({ menuItemId: objectId })
    .sort({ createdAt: -1 })
    .toArray();
}

async function getUserReviews(userId) {
  if (!userId) {
    throw createAppError("User authentication is required", 401);
  }

  return getReviewsCollection()
    .find({ userId })
    .sort({ createdAt: -1 })
    .toArray();
}

async function updateReview(userId, reviewId, updates = {}) {
  if (!userId) {
    throw createAppError("User authentication is required", 401);
  }

  const objectId = ensureObjectId(reviewId, "reviewId");

  const existingReview = await getReviewsCollection().findOne({
    _id: objectId,
  });

  if (!existingReview) {
    throw createAppError("Review not found", 404);
  }

  if (existingReview.userId !== userId) {
    throw createAppError("You can only update your own review", 403);
  }

  const updateData = {};

  if (updates.rating !== undefined) {
    const normalizedRating = Number(updates.rating);

    if (!Number.isInteger(normalizedRating) || normalizedRating < 1 || normalizedRating > 5) {
      throw createAppError("rating must be an integer from 1 to 5", 400);
    }

    updateData.rating = normalizedRating;
  }

  if (updates.review !== undefined) {
    const reviewText = normalizeReviewText(updates.review);

    if (reviewText.length > 500) {
      throw createAppError("review must be 500 characters or fewer", 400);
    }

    updateData.review = reviewText;
  }

  if (Object.keys(updateData).length === 0) {
    throw createAppError("At least one field is required", 400);
  }

  updateData.updatedAt = new Date();

  const result = await getReviewsCollection().findOneAndUpdate(
    { _id: objectId, userId },
    { $set: updateData },
    { returnDocument: "after" }
  );

  if (!result) {
    throw createAppError("Review could not be updated", 500);
  }

  return result;
}

async function deleteReview(userId, reviewId) {
  if (!userId) {
    throw createAppError("User authentication is required", 401);
  }

  const objectId = ensureObjectId(reviewId, "reviewId");

  const existingReview = await getReviewsCollection().findOne({
    _id: objectId,
  });

  if (!existingReview) {
    throw createAppError("Review not found", 404);
  }

  if (existingReview.userId !== userId) {
    throw createAppError("You can only delete your own review", 403);
  }

  const result = await getReviewsCollection().deleteOne({
    _id: objectId,
    userId,
  });

  if (result.deletedCount === 0) {
    throw createAppError("Review could not be deleted", 500);
  }

  return {
    deleted: true,
    _id: objectId,
  };
}

async function getRatingSummary(menuItemId) {
  const objectId = ensureObjectId(menuItemId, "menuItemId");

  await ensureMenuItemExists(menuItemId);

  const result = await getReviewsCollection()
    .aggregate([
      {
        $match: {
          menuItemId: objectId,
        },
      },
      {
        $group: {
          _id: "$menuItemId",
          averageRating: { $avg: "$rating" },
          ratingCount: { $sum: 1 },
          one: {
            $sum: {
              $cond: [{ $eq: ["$rating", 1] }, 1, 0],
            },
          },
          two: {
            $sum: {
              $cond: [{ $eq: ["$rating", 2] }, 1, 0],
            },
          },
          three: {
            $sum: {
              $cond: [{ $eq: ["$rating", 3] }, 1, 0],
            },
          },
          four: {
            $sum: {
              $cond: [{ $eq: ["$rating", 4] }, 1, 0],
            },
          },
          five: {
            $sum: {
              $cond: [{ $eq: ["$rating", 5] }, 1, 0],
            },
          },
        },
      },
      {
        $project: {
          _id: 0,
          averageRating: {
            $round: ["$averageRating", 2],
          },
          ratingCount: 1,
          distribution: {
            1: "$one",
            2: "$two",
            3: "$three",
            4: "$four",
            5: "$five",
          },
        },
      },
    ])
    .toArray();

  if (!result.length) {
    return {
      averageRating: 0,
      ratingCount: 0,
      distribution: {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
      },
    };
  }

  const summary = result[0];

  return {
    averageRating: Number(summary.averageRating || 0),
    ratingCount: Number(summary.ratingCount || 0),
    distribution: {
      1: Number(summary.distribution?.[1] || 0),
      2: Number(summary.distribution?.[2] || 0),
      3: Number(summary.distribution?.[3] || 0),
      4: Number(summary.distribution?.[4] || 0),
      5: Number(summary.distribution?.[5] || 0),
    },
  };
}

module.exports = {
  createReview,
  getReviewsForMenuItem,
  getUserReviews,
  updateReview,
  deleteReview,
  getRatingSummary,
  ensureReviewIndexes,
  buildRatingSummaryFromRows,
  hasPurchasedMenuItem,
};
