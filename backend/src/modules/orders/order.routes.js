const express = require("express");

const orderController = require("./order.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { requireCampusAccess } = require("../../middleware/campusAccess.middleware");
const { requireRole } = require("../../middleware/role.middleware");
const { ROLES } = require("../../common/constants/roles");
const {
  validateCreateOrder,
  validateOrderStatus,
} = require("./order.validator");

const router = express.Router();

router.use(authenticate);

router.post(
  "/",
  validateCreateOrder,
  requireCampusAccess,
  orderController.createOrder
);

router.get(
  "/",
  orderController.getMyOrders
);

router.get(
  "/all",
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  orderController.getAllOrders
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
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  validateOrderStatus,
  orderController.updateOrderStatus
);

router.patch(
  "/:id/cancel",
  orderController.cancelOrder
);

router.patch(
  "/:id/no-show",
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  orderController.markNoShow
);

router.patch(
  "/:id/release",
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  orderController.releaseUncollectedOrder
);

module.exports = router;