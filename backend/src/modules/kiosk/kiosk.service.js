const QRCode = require("qrcode");
const { createCampusCheckinChallenge } = require("../auth/auth.service");
const config = require("../../config/env");

/**
 * Generates a fresh short-lived HMAC signed campus kiosk check-in challenge
 * and renders it as a QR code Data URL.
 */
async function generateKioskQR() {
  const expiresInSeconds = 120; // 2 minutes single-use challenge
  const challenge = createCampusCheckinChallenge({ expiresIn: expiresInSeconds });
  
  const qrDataUrl = await QRCode.toDataURL(challenge, {
    errorCorrectionLevel: "M",
    margin: 2,
    color: {
      dark: "#1A1A1A",
      light: "#FFFFFF",
    },
    width: 320,
  });

  return {
    challenge,
    qrDataUrl,
    campusId: config.campusAccess?.campusId || process.env.CAMPUS_ID || "PES_RR_CAMPUS",
    expiresIn: expiresInSeconds,
    issuedAt: new Date().toISOString(),
  };
}

module.exports = {
  generateKioskQR,
};
