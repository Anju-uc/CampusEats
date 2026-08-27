const ROLES = Object.freeze({
    STUDENT: "student",
    KITCHEN: "kitchen",
    ADMIN: "admin",
  });
  
  const VALID_ROLES = Object.freeze(
    Object.values(ROLES)
  );
  
  module.exports = {
    ROLES,
    VALID_ROLES,
  };