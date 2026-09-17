require("dotenv").config();

const app = require("./app");
const { connectMongoDB, getDb } = require("./config/mongodb");
const config = require("./config/env");
const { ensureReviewIndexes } = require("./modules/reviews/review.service");

async function ensureDatabaseIndexes() {
  const db = getDb();

  await db.collection("reviews").createIndex({ userId: 1 });
  await db.collection("reviews").createIndex({ menuItemId: 1 });
  await db.collection("reviews").createIndex(
    { userId: 1, menuItemId: 1 },
    { unique: true }
  );

  await db.collection("orders").createIndex({ userId: 1 });
  await db.collection("orders").createIndex({ createdAt: -1 });
  await db.collection("orders").createIndex({ "items.menuItemId": 1 });
  await db.collection("users").createIndex(
    { studentId: 1 },
    { unique: true, sparse: true }
  );
  await db.collection("studentRegistry").createIndex(
    { studentId: 1 },
    { unique: true }
  );
  await db.collection("studentRegistry").createIndex({ status: 1 });
  await db.collection("studentRegistry").createIndex({ program: 1 });
  await db.collection("carts").createIndex(
    { userId: 1 },
    { unique: true }
  );
  await db.collection("campusAccessProofs").createIndex(
    { jti: 1 },
    { unique: true }
  );
  await db.collection("campusAccessProofs").createIndex(
    { expiresAt: 1 },
    { expireAfterSeconds: 0 }
  );

  await ensureReviewIndexes();
}

async function startServer() {
  try {
    await connectMongoDB();
    await ensureDatabaseIndexes();

    app.listen(config.port, () => {
      console.log(
        `CampusEATS backend running on http://localhost:${config.port}`
      );
    });
  } catch (error) {
    console.error("Failed to start server:", error.message);
    process.exit(1);
  }
}

startServer();