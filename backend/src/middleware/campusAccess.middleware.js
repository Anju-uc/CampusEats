const crypto = require("node:crypto");
const { getDb } = require("../config/mongodb");
const { ROLES } = require("../common/constants/roles");

function decodePart(value) {
  return JSON.parse(Buffer.from(value, "base64url").toString("utf8"));
}

function reject(res, statusCode, message) {
  return res.status(statusCode).json({
    status: "error",
    message,
  });
}

async function requireCampusAccess(req, res, next) {
  if (!req.user || req.user.role !== ROLES.STUDENT || req.user.status !== "ACTIVE") {
    return reject(res, 403, "An active student account is required");
  }

  const secret = process.env.CAMPUS_ACCESS_SECRET;
  const campusId = process.env.CAMPUS_ID;
  const proof = req.headers["x-campus-access-proof"];

  if (!secret || !campusId) {
    return reject(res, 503, "Campus access verification is not configured");
  }

  if (typeof proof !== "string") {
    return reject(res, 403, "Valid campus access is required");
  }

  const parts = proof.split(".");

  if (parts.length !== 2) {
    return reject(res, 403, "Valid campus access is required");
  }

  const [payloadPart, signaturePart] = parts;
  const expectedSignature = crypto
    .createHmac("sha256", secret)
    .update(payloadPart)
    .digest("base64url");

  const providedSignature = Buffer.from(signaturePart);
  const expectedSignatureBuffer = Buffer.from(expectedSignature);
  const signaturesMatch =
    providedSignature.length === expectedSignatureBuffer.length &&
    crypto.timingSafeEqual(providedSignature, expectedSignatureBuffer);

  if (!signaturesMatch) {
    return reject(res, 403, "Valid campus access is required");
  }

  try {
    const payload = decodePart(payloadPart);
    const now = Math.floor(Date.now() / 1000);

    if (
      payload.campusId !== campusId ||
      payload.uid !== req.user.uid ||
      !Number.isInteger(payload.exp) ||
      payload.exp <= now ||
      !Number.isInteger(payload.iat) ||
      payload.iat > now ||
      payload.exp - payload.iat > 300 ||
      typeof payload.jti !== "string" ||
      payload.jti.length < 16 ||
      payload.jti.length > 128
    ) {
      return reject(res, 403, "Campus access proof has expired");
    }

    try {
      await getDb().collection("campusAccessProofs").insertOne({
        jti: payload.jti,
        campusId: payload.campusId,
        expiresAt: new Date(payload.exp * 1000),
        consumedAt: new Date(),
      });
    } catch (error) {
      if (error.code === 11000) {
        return reject(res, 403, "Campus access proof has already been used");
      }

      throw error;
    }

    req.campusAccess = payload;
    next();
  } catch (error) {
    return reject(res, 403, "Valid campus access is required");
  }
}

module.exports = {
  requireCampusAccess,
};
