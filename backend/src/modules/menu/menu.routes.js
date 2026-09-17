const express = require("express");

const menuController = require("./menu.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const { requireRole } = require("../../middleware/role.middleware");
const { ROLES } = require("../../common/constants/roles");
const {
  validateMenuItem,
  validateMenuUpdate,
} = require("./menu.validator");

const router = express.Router();

router.get("/", menuController.getAllMenuItems);
router.get("/available", menuController.getAvailableMenuItems);
router.get("/:id", menuController.getMenuItemById);

router.post(
  "/",
  authenticate,
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  validateMenuItem,
  menuController.createMenuItem
);

router.put(
  "/:id",
  authenticate,
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  validateMenuUpdate,
  menuController.updateMenuItem
);

router.delete(
  "/:id",
  authenticate,
  requireRole(ROLES.ADMIN, ROLES.KITCHEN, ROLES.FACULTY),
  menuController.deleteMenuItem
);

module.exports = router;