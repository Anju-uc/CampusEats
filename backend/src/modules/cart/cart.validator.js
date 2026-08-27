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
      numericQuantity < 1
    ) {
      return res.status(400).json({
        status: "error",
        message: "quantity must be a positive integer",
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
      numericQuantity < 1
    ) {
      return res.status(400).json({
        status: "error",
        message: "quantity must be a positive integer",
      });
    }
  
    next();
  }
  
  module.exports = {
    validateAddToCart,
    validateUpdateCartItem,
  };