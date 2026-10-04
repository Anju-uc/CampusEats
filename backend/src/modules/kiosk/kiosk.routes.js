const express = require("express");
const router = express.Router();
const { getKioskChallenge, renderKioskPage } = require("./kiosk.controller");

router.get("/challenge", getKioskChallenge);
router.get("/view", renderKioskPage);

module.exports = router;
