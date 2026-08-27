const express = require("express");

const orderController = require("./order.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const {
  validateCreateOrder,
  validateOrderStatus,
} = require("./order.validator");

const router = express.Router();

router.use(authenticate);

router.post(
  "/",
  validateCreateOrder,
  orderController.createOrder
);

router.get(
  "/",
  orderController.getMyOrders
);

// IMPORTANT: keep /:id/eta BEFORE /:id
router.get(
  "/:id/eta",
  orderController.getEta
);

router.get(
  "/:id",
  orderController.getOrderById
);

router.patch(
  "/:id/status",
  validateOrderStatus,
  orderController.updateOrderStatus
);

router.patch(
  "/:id/cancel",
  orderController.cancelOrder
);

module.exports = router;