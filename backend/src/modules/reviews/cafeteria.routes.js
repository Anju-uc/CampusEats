const express = require("express");

const reviewController = require("./review.controller");
const { authenticate } = require("../../middleware/auth.middleware");

const router = express.Router();

router.use(authenticate);

router.get("/:cafeteria/reviews", reviewController.getCafeteriaReviews);
router.get("/:cafeteria/rating", reviewController.getCafeteriaRating);

module.exports = router;
