const express = require("express");

const reviewController = require("./review.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const {
  validateCreateReview,
  validateUpdateReview,
  validateMenuItemParam,
  validateReviewIdParam,
} = require("./review.validator");

const router = express.Router();

router.use(authenticate);

router.post("/", validateCreateReview, reviewController.createReview);

router.get(
  "/menu/:menuItemId",
  validateMenuItemParam,
  reviewController.getReviewsForMenuItem
);

router.get("/me", reviewController.getUserReviews);

router.get(
  "/menu/:menuItemId/summary",
  validateMenuItemParam,
  reviewController.getRatingSummary
);

router.patch(
  "/:id",
  validateReviewIdParam,
  validateUpdateReview,
  reviewController.updateReview
);

router.delete(
  "/:id",
  validateReviewIdParam,
  reviewController.deleteReview
);

module.exports = router;
