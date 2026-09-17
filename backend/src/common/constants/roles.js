const ROLES = Object.freeze({
  STUDENT: "Student",
  ADMIN: "Admin",
  KITCHEN: "Kitchen",
  FACULTY: "Faculty",
  });
  
  const VALID_ROLES = Object.freeze(
    Object.values(ROLES)
  );
  
  module.exports = {
    ROLES,
    VALID_ROLES,
  };