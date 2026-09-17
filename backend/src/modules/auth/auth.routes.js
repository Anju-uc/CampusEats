const express = require("express");

const authController = require("./auth.controller");
const {
  validateRegister,
  validateLogin,
  validateStudentStatus,
} = require("./auth.validator");
const { authenticate } = require("../../middleware/auth.middleware");
const { requireRole } = require("../../middleware/role.middleware");
const { ROLES } = require("../../common/constants/roles");

const router = express.Router();

router.post("/register", validateRegister, authController.register);
router.post("/login", validateLogin, authController.login);

router.patch(
  "/students/:studentId/status",
  authenticate,
  requireRole(ROLES.ADMIN, ROLES.FACULTY),
  validateStudentStatus,
  authController.updateStudentStatus
);

module.exports = router;