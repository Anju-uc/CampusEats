const express = require("express");

const userController = require("./user.controller");
const { authenticate } = require("../../middleware/auth.middleware");

const router = express.Router();

router.get("/me", authenticate, userController.getMe);
router.put("/me", authenticate, userController.updateMe);

module.exports = router;