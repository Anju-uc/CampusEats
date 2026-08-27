const cartService = require("./cart.service");

async function getCart(req, res, next) {
  try {
    const cart = await cartService.getCart(req.user.uid);

    res.status(200).json({
      status: "success",
      data: cart,
    });
  } catch (error) {
    next(error);
  }
}

async function addToCart(req, res, next) {
  try {
    const cart = await cartService.addToCart(
      req.user.uid,
      req.body.menuItemId,
      Number(req.body.quantity)
    );

    res.status(200).json({
      status: "success",
      message: "Item added to cart",
      data: cart,
    });
  } catch (error) {
    next(error);
  }
}

async function updateCartItem(req, res, next) {
  try {
    const cart = await cartService.updateCartItem(
      req.user.uid,
      req.params.menuItemId,
      Number(req.body.quantity)
    );

    res.status(200).json({
      status: "success",
      message: "Cart item updated",
      data: cart,
    });
  } catch (error) {
    next(error);
  }
}

async function removeFromCart(req, res, next) {
  try {
    const cart = await cartService.removeFromCart(
      req.user.uid,
      req.params.menuItemId
    );

    res.status(200).json({
      status: "success",
      message: "Item removed from cart",
      data: cart,
    });
  } catch (error) {
    next(error);
  }
}

async function clearCart(req, res, next) {
  try {
    const cart = await cartService.clearCart(req.user.uid);

    res.status(200).json({
      status: "success",
      message: "Cart cleared",
      data: cart,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
};