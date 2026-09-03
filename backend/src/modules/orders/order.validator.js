function validateCreateOrder(req, res, next) {
    const { notes } = req.body;
  
    if (notes !== undefined && typeof notes !== "string") {
      return res.status(400).json({
        status: "error",
        message: "notes must be a string",
      });
    }
  
    next();
  }
  
  function validateOrderStatus(req, res, next) {
    const { status } = req.body;
  
    if (!status || typeof status !== "string") {
      return res.status(400).json({
        status: "error",
        message: "status is required",
      });
    }
  
    next();
  }
  
  module.exports = {
    validateCreateOrder,
    validateOrderStatus,
  };