const express = require("express");

const { authenticate } = require("../../middleware/auth.middleware");

const {
  getRecommendations,
} = require("./recommendations/recommendation.service");

const {
  getDemand,
} = require("./demand/demand.service");

const router = express.Router();

router.get(
  "/recommendations",
  authenticate,
  async (req, res, next) => {
    try {
      const recommendations = await getRecommendations(
        req.user.uid
      );

      res.status(200).json({
        status: "success",
        data: recommendations,
      });
    } catch (error) {
      next(error);
    }
  }
);

router.get(
  "/demand",
  authenticate,
  async (req, res, next) => {
    try {
      const demand = await getDemand();

      res.status(200).json({
        status: "success",
        data: demand,
      });
    } catch (error) {
      next(error);
    }
  }
);

module.exports = router;