require("dotenv").config();

const app = require("./app");
const { connectMongoDB, getDb } = require("./config/mongodb");
const config = require("./config/env");
const { ensureReviewIndexes } = require("./modules/reviews/review.service");

async function ensureDatabaseIndexes() {
  const db = getDb();

  const safeCreateIndex = async (collection, spec, options) => {
    try {
      await db.collection(collection).createIndex(spec, options);
    } catch (_) {}
  };

  await safeCreateIndex("reviews", { userId: 1 });
  await safeCreateIndex("reviews", { orderId: 1 }, { unique: true, sparse: true });
  await safeCreateIndex("reviews", { cafeteria: 1 });

  await safeCreateIndex("orders", { userId: 1 });
  await safeCreateIndex("orders", { createdAt: -1 });
  await safeCreateIndex("orders", { "items.menuItemId": 1 });
  await safeCreateIndex("users", { studentId: 1 }, { unique: true, sparse: true });
  await safeCreateIndex("users", { uid: 1 });
  await safeCreateIndex("studentRegistry", { studentId: 1 }, { unique: true });
  await safeCreateIndex("studentRegistry", { status: 1 });
  await safeCreateIndex("studentRegistry", { program: 1 });
  await safeCreateIndex("carts", { userId: 1 }, { unique: true });
  await safeCreateIndex("campusAccessProofs", { jti: 1 }, { unique: true });
  await safeCreateIndex("campusAccessProofs", { expiresAt: 1 }, { expireAfterSeconds: 0 });
  await safeCreateIndex("payments", { cashfreeOrderId: 1 }, { unique: true, sparse: true });
  await safeCreateIndex("payments", { razorpayOrderId: 1 }, { unique: true, sparse: true });
  await safeCreateIndex("payments", { userId: 1 });
  await safeCreateIndex("payments", { status: 1 });
  await safeCreateIndex("payments", { createdAt: -1 });
  await safeCreateIndex("payments", { campusEatsOrderId: 1 });

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