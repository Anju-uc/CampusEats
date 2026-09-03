function validateBody(schema) {
    return (req, res, next) => {
      if (typeof schema !== "function") {
        return res.status(500).json({
          status: "error",
          message: "Validation schema is not configured correctly",
        });
      }
  
      const result = schema(req.body);
  
      if (!result || result.valid !== true) {
        return res.status(400).json({
          status: "error",
          message:
            result?.message ||
            "Request body validation failed",
        });
      }
  
      next();
    };
  }
  
  function validateParams(schema) {
    return (req, res, next) => {
      if (typeof schema !== "function") {
        return res.status(500).json({
          status: "error",
          message: "Validation schema is not configured correctly",
        });
      }
  
      const result = schema(req.params);
  
      if (!result || result.valid !== true) {
        return res.status(400).json({
          status: "error",
          message:
            result?.message ||
            "Request parameters validation failed",
        });
      }
  
      next();
    };
  }
  
  function validateQuery(schema) {
    return (req, res, next) => {
      if (typeof schema !== "function") {
        return res.status(500).json({
          status: "error",
          message: "Validation schema is not configured correctly",
        });
      }
  
      const result = schema(req.query);
  
      if (!result || result.valid !== true) {
        return res.status(400).json({
          status: "error",
          message:
            result?.message ||
            "Request query validation failed",
        });
      }
  
      next();
    };
  }
  
  module.exports = {
    validateBody,
    validateParams,
    validateQuery,
  };