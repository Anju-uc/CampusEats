const MAX_CART_QUANTITY = 99;

function validateAddToCart(req, res, next) {
    const { menuItemId, quantity } = req.body;
  
    if (!menuItemId || quantity === undefined) {
      return res.status(400).json({
        status: "error",
        message: "menuItemId and quantity are required",
      });
    }
  
    const numericQuantity = Number(quantity);
  
    if (
      !Number.isInteger(numericQuantity) ||
      numericQuantity < 1 ||
      numericQuantity > MAX_CART_QUANTITY
    ) {
      return res.status(400).json({
        status: "error",
        message: `quantity must be an integer from 1 to ${MAX_CART_QUANTITY}`,
      });
    }
  
    next();
  }
  
  function validateUpdateCartItem(req, res, next) {
    const { quantity } = req.body;
  
    if (quantity === undefined) {
      return res.status(400).json({
        status: "error",
        message: "quantity is required",
      });
    }
  
    const numericQuantity = Number(quantity);
  
    if (
      !Number.isInteger(numericQuantity) ||
      numericQuantity < 1 ||
      numericQuantity > MAX_CART_QUANTITY
    ) {
      return res.status(400).json({
        status: "error",
        message: `quantity must be an integer from 1 to ${MAX_CART_QUANTITY}`,
      });
    }
  
    next();
  }
  
  module.exports = {
    MAX_CART_QUANTITY,
    validateAddToCart,
    validateUpdateCartItem,
  };