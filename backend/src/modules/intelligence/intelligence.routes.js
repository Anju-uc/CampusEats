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
      const rawLimit = req.query.limit;
      const limit = Number(rawLimit);

      if (rawLimit !== undefined && (!Number.isInteger(limit) || limit < 1 || limit > 10)) {
        return res.status(400).json({
          status: "error",
          message: "limit must be an integer between 1 and 10",
        });
      }

      const recommendations = await getRecommendations(
        req.user.uid,
        { limit: rawLimit === undefined ? 5 : limit }
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