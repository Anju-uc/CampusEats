function validateRegister(req, res, next) {
    const { name, email, password } = req.body;
  
    if (!name || !email || !password) {
      return res.status(400).json({
        status: "error",
        message: "name, email and password are required",
      });
    }
  
    if (typeof email !== "string" || !email.includes("@")) {
      return res.status(400).json({
        status: "error",
        message: "A valid email is required",
      });
    }
  
    if (typeof password !== "string" || password.length < 6) {
      return res.status(400).json({
        status: "error",
        message: "Password must be at least 6 characters",
      });
    }
  
    next();
  }
  
  function validateLogin(req, res, next) {
    const { email, password } = req.body;
  
    if (!email || !password) {
      return res.status(400).json({
        status: "error",
        message: "email and password are required",
      });
    }
  
    next();
  }
  
  module.exports = {
    validateRegister,
    validateLogin,
  };