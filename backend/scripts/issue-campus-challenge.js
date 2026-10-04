require("dotenv").config();
const { createCampusCheckinChallenge } = require("../src/modules/auth/auth.service");

try {
  const challenge = createCampusCheckinChallenge({ expiresIn: 120 });
  console.log("==========================================");
  console.log(" TRUSTED CAMPUS KIOSK / CHECK-IN ISSUER ");
  console.log("==========================================");
  console.log("Generated short-lived campus check-in challenge (valid for 2 mins):\n");
  console.log(challenge);
  console.log("\n==========================================");
  console.log("Copy or scan this challenge into CampusEats app during campus check-in.");
  console.log("==========================================");
} catch (err) {
  console.error("Failed to generate campus check-in challenge:", err.message);
  process.exit(1);
}
