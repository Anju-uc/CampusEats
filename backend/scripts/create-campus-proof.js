const crypto = require("node:crypto");

const uid = process.argv[2];
const secret = process.env.CAMPUS_ACCESS_SECRET;
const campusId = process.env.CAMPUS_ID;

if (!uid || !secret || !campusId) {
  console.error(
    "Usage: CAMPUS_ACCESS_SECRET=... CAMPUS_ID=... node scripts/create-campus-proof.js <firebase-uid>"
  );
  process.exitCode = 1;
} else {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 60;
  const payload = Buffer.from(
    JSON.stringify({
      uid,
      campusId,
      iat,
      exp,
      jti: crypto.randomUUID(),
    })
  ).toString("base64url");
  const signature = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("base64url");

  process.stdout.write(`${payload}.${signature}\n`);
}