const { ObjectId } = require("mongodb");

function validateCreateReview(req, res, next) {
  const { menuItemId, rating, review } = req.body;

  if (!menuItemId || typeof menuItemId !== "string") {
    return res.status(400).json({
      status: "error",
      message: "menuItemId is required",
    });
  }

  if (!ObjectId.isValid(menuItemId)) {
    return res.status(400).json({
      status: "error",
      message: "menuItemId must be a valid MongoDB ObjectId",
    });
  }

  const numericRating = Number(rating);

  if (!Number.isInteger(numericRating) || numericRating < 1 || numericRating > 5) {
    return res.status(400).json({
      status: "error",
      message: "rating must be an integer from 1 to 5",
    });
  }

  if (review !== undefined && review !== null && typeof review !== "string") {
    return res.status(400).json({
      status: "error",
      message: "review must be a string when provided",
    });
  }

  if (review !== undefined && review !== null && review.trim().length > 500) {
    return res.status(400).json({
      status: "error",
      message: "review must be 500 characters or fewer",
    });
  }

  next();
}

function validateUpdateReview(req, res, next) {
  const { rating, review } = req.body;

  if (rating === undefined && review === undefined) {
    return res.status(400).json({
      status: "error",
      message: "At least one field is required",
    });
  }

  if (rating !== undefined) {
    const numericRating = Number(rating);

    if (!Number.isInteger(numericRating) || numericRating < 1 || numericRating > 5) {
      return res.status(400).json({
        status: "error",
        message: "rating must be an integer from 1 to 5",
      });
    }
  }

  if (review !== undefined) {
    if (typeof review !== "string") {
      return res.status(400).json({
        status: "error",
        message: "review must be a string when provided",
      });
    }

    if (review.trim().length > 500) {
      return res.status(400).json({
        status: "error",
        message: "review must be 500 characters or fewer",
      });
    }
  }

  next();
}

function validateMenuItemParam(req, res, next) {
  const { menuItemId } = req.params;

  if (!menuItemId || !ObjectId.isValid(menuItemId)) {
    return res.status(400).json({
      status: "error",
      message: "menuItemId must be a valid MongoDB ObjectId",
    });
  }

  next();
}

function validateReviewIdParam(req, res, next) {
  const { id } = req.params;

  if (!id || !ObjectId.isValid(id)) {
    return res.status(400).json({
      status: "error",
      message: "Review ID must be a valid MongoDB ObjectId",
    });
  }

  next();
}

module.exports = {
  validateCreateReview,
  validateUpdateReview,
  validateMenuItemParam,
  validateReviewIdParam,
};
