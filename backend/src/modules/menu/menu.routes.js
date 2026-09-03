const express = require("express");

const menuController = require("./menu.controller");
const {
  validateMenuItem,
  validateMenuUpdate,
} = require("./menu.validator");

const router = express.Router();

router.get("/", menuController.getAllMenuItems);
router.get("/available", menuController.getAvailableMenuItems);
router.get("/:id", menuController.getMenuItemById);

router.post("/", validateMenuItem, menuController.createMenuItem);

router.put(
  "/:id",
  validateMenuUpdate,
  menuController.updateMenuItem
);

router.delete("/:id", menuController.deleteMenuItem);

module.exports = router;