const { VALID_ROLES } = require("../common/constants/roles");

function requireRole(...allowedRoles) {
    const canonicalAllowedRoles = allowedRoles.filter((role) =>
      VALID_ROLES.includes(role)
    );

    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          status: "error",
          message: "Authentication is required",
        });
      }
  
      const userRole = req.user.role;
  
      if (!userRole) {
        return res.status(403).json({
          status: "error",
          message: "User role is not assigned",
        });
      }
  
      if (
        !VALID_ROLES.includes(userRole) ||
        !canonicalAllowedRoles.includes(userRole)
      ) {
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