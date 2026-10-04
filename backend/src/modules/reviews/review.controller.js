const reviewService = require("./review.service");

async function createReview(req, res, next) {
  try {
    const review = await reviewService.createReview(
      req.user.uid,
      req.body,
      req.body.rating,
      req.body.review,
      req.user.role
    );

    res.status(201).json({
      status: "success",
      message: "Review created successfully",
      data: review,
    });
  } catch (error) {
    next(error);
  }
}

async function getOrderReview(req, res, next) {
  try {
    const review = await reviewService.getOrderReview(
      req.params.orderId,
      req.user
    );

    res.status(200).json({
      status: "success",
      data: review,
    });
  } catch (error) {
    next(error);
  }
}

async function getReviewsForMenuItem(req, res, next) {
  try {
    const reviews = await reviewService.getReviewsForMenuItem(
      req.params.menuItemId
    );

    res.status(200).json({
      status: "success",
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
}

async function getUserReviews(req, res, next) {
  try {
    const reviews = await reviewService.getUserReviews(req.user.uid);

    res.status(200).json({
      status: "success",
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
}

async function getCafeteriaReviews(req, res, next) {
  try {
    const reviews = await reviewService.getCafeteriaReviews(
      req.params.cafeteria,
      req.user
    );

    res.status(200).json({
      status: "success",
      data: reviews,
    });
  } catch (error) {
    next(error);
  }
}

async function getCafeteriaRating(req, res, next) {
  try {
    const summary = await reviewService.getCafeteriaRatingSummary(
      req.params.cafeteria
    );

    res.status(200).json({
      status: "success",
      data: summary,
    });
  } catch (error) {
    next(error);
  }
}

async function getRatingSummary(req, res, next) {
  try {
    const summary = await reviewService.getRatingSummary(
      req.params.menuItemId
    );

    res.status(200).json({
      status: "success",
      data: summary,
    });
  } catch (error) {
    next(error);
  }
}

async function updateReview(req, res, next) {
  try {
    const review = await reviewService.updateReview(
      req.user.uid,
      req.params.id,
      req.body
    );

    res.status(200).json({
      status: "success",
      message: "Review updated successfully",
      data: review,
    });
  } catch (error) {
    next(error);
  }
}

async function deleteReview(req, res, next) {
  try {
    const result = await reviewService.deleteReview(
      req.user.uid,
      req.params.id
    );

    res.status(200).json({
      status: "success",
      message: "Review deleted successfully",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createReview,
  getOrderReview,
  getReviewsForMenuItem,
  getUserReviews,
  getCafeteriaReviews,
  getCafeteriaRating,
  getRatingSummary,
  updateReview,
  deleteReview,
};
