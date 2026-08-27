function requireRole(...allowedRoles) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          status: "error",
          message: "Authentication is required",
        });
      }
  
      const userRole =
        req.user.role ||
        req.user.customClaims?.role;
  
      if (!userRole) {
        return res.status(403).json({
          status: "error",
          message: "User role is not assigned",
        });
      }
  
      if (!allowedRoles.includes(userRole)) {
        return res.status(403).json({
          status: "error",
          message: "You do not have permission to perform this action",
        });
      }
  
      next();
    };
  }
  
  module.exports = {
    requireRole,
  };