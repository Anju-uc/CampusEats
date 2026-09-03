function validateMenuItem(req, res, next) {
    const {
      name,
      description,
      price,
      category,
      imageUrl,
      available,
    } = req.body;
  
    if (!name || !category || price === undefined) {
      return res.status(400).json({
        status: "error",
        message: "name, category and price are required",
      });
    }
  
    const numericPrice = Number(price);
  
    if (!Number.isFinite(numericPrice) || numericPrice < 0) {
      return res.status(400).json({
        status: "error",
        message: "price must be a valid non-negative number",
      });
    }
  
    if (description !== undefined && typeof description !== "string") {
      return res.status(400).json({
        status: "error",
        message: "description must be a string",
      });
    }
  
    if (imageUrl !== undefined && typeof imageUrl !== "string") {
      return res.status(400).json({
        status: "error",
        message: "imageUrl must be a string",
      });
    }
  
    if (available !== undefined && typeof available !== "boolean") {
      return res.status(400).json({
        status: "error",
        message: "available must be true or false",
      });
    }
  
    next();
  }
  
  function validateMenuUpdate(req, res, next) {
    const allowedFields = [
      "name",
      "description",
      "price",
      "category",
      "imageUrl",
      "available",
    ];
  
    const providedFields = Object.keys(req.body);
  
    if (providedFields.length === 0) {
      return res.status(400).json({
        status: "error",
        message: "At least one field is required",
      });
    }
  
    const invalidFields = providedFields.filter(
      (field) => !allowedFields.includes(field)
    );
  
    if (invalidFields.length > 0) {
      return res.status(400).json({
        status: "error",
        message: `Invalid fields: ${invalidFields.join(", ")}`,
      });
    }
  
    if (req.body.price !== undefined) {
      const numericPrice = Number(req.body.price);
  
      if (!Number.isFinite(numericPrice) || numericPrice < 0) {
        return res.status(400).json({
          status: "error",
          message: "price must be a valid non-negative number",
        });
      }
    }
  
    if (
      req.body.available !== undefined &&
      typeof req.body.available !== "boolean"
    ) {
      return res.status(400).json({
        status: "error",
        message: "available must be true or false",
      });
    }
  
    next();
  }
  
  module.exports = {
    validateMenuItem,
    validateMenuUpdate,
  };