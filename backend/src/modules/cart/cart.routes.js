const express = require("express");

const cartController = require("./cart.controller");
const { authenticate } = require("../../middleware/auth.middleware");
const {
  validateAddToCart,
  validateUpdateCartItem,
} = require("./cart.validator");

const router = express.Router();

router.use(authenticate);

router.get("/", cartController.getCart);

router.post(
  "/items",
  validateAddToCart,
  cartController.addToCart
);

router.put(
  "/items/:menuItemId",
  validateUpdateCartItem,
  cartController.updateCartItem
);

router.delete(
  "/items/:menuItemId",
  cartController.removeFromCart
);

router.delete("/", cartController.clearCart);

module.exports = router;