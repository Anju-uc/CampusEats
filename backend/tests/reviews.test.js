const test = require("node:test");
const assert = require("node:assert/strict");

const { ObjectId } = require("mongodb");
const { getDb } = require("../src/config/mongodb");
const { connectMongoDB } = require("../src/config/mongodb");
const reviewService = require("../src/modules/reviews/review.service");
const { getRecommendations } = require("../src/modules/intelligence/recommendations/recommendation.service");

const SAMPLE_MENU = {
  _id: new ObjectId(),
  name: "Test Noodles",
  description: "Test item",
  price: 100,
  category: "Fast Food",
  imageUrl: "test.png",
  available: true,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const SAMPLE_MENU_2 = {
  _id: new ObjectId(),
  name: "Test Salad",
  description: "Another test item",
  price: 80,
  category: "Healthy",
  imageUrl: "salad.png",
  available: true,
  createdAt: new Date(),
  updatedAt: new Date(),
};

async function seedMenuAndOrders() {
  const db = getDb();
  await db.collection("menu").deleteMany({});
  await db.collection("orders").deleteMany({});
  await db.collection("reviews").deleteMany({});
  await db.collection("carts").deleteMany({});
  await db.collection("menu").insertMany([SAMPLE_MENU, SAMPLE_MENU_2]);
}

test("review valid review is created", async () => {
  await connectMongoDB();
  await seedMenuAndOrders();

  const data = await reviewService.createReview("user-1", SAMPLE_MENU._id.toString(), 5, "Excellent");
  assert.equal(data.userId, "user-1");
  assert.equal(data.rating, 5);
  assert.equal(data.review, "Excellent");
});

test("invalid rating is rejected", async () => {
  await assert.rejects(
    () => reviewService.createReview("user-2", SAMPLE_MENU._id.toString(), 6, "bad"),
    (error) => error.statusCode === 400
  );
});

test("invalid menu item is rejected", async () => {
  await assert.rejects(
    () => reviewService.createReview("user-2", "invalid-id", 5, "bad"),
    (error) => error.statusCode === 400
  );
});

test("duplicate review is rejected", async () => {
  await assert.rejects(
    () => reviewService.createReview("user-1", SAMPLE_MENU._id.toString(), 4, "Again"),
    (error) => error.statusCode === 409
  );
});

test("rating summary is calculated with aggregation", async () => {
  const summary = await reviewService.getRatingSummary(SAMPLE_MENU._id.toString());
  assert.equal(summary.ratingCount, 1);
  assert.equal(summary.averageRating, 5);
  assert.deepEqual(summary.distribution, { 1: 0, 2: 0, 3: 0, 4: 0, 5: 1 });
});

test("recommendation cold start returns diverse popular items", async () => {
  const items = await getRecommendations("cold-user");
  assert.ok(Array.isArray(items));
  assert.ok(items.length <= 5);
  assert.ok(items.every((item) => item.available !== false));
});

test("recommendation personalization uses user history", async () => {
  const db = getDb();
  await db.collection("orders").insertOne({
    userId: "personal-user",
    status: "DELIVERED",
    items: [
      { menuItemId: SAMPLE_MENU._id, quantity: 2, name: SAMPLE_MENU.name, price: SAMPLE_MENU.price },
      { menuItemId: SAMPLE_MENU_2._id, quantity: 1, name: SAMPLE_MENU_2.name, price: SAMPLE_MENU_2.price },
    ],
    total: 280,
    createdAt: new Date(),
  });

  await db.collection("reviews").insertOne({
    userId: "personal-user",
    menuItemId: SAMPLE_MENU._id,
    rating: 5,
    review: "Liked it",
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  const items = await getRecommendations("personal-user");
  assert.ok(items.length > 0);
  const first = items[0];
  assert.equal(first.category, "Fast Food");
});

test("recommendation excludes unavailable and cart items", async () => {
  const db = getDb();
  await db.collection("menu").updateOne(
    { _id: SAMPLE_MENU_2._id },
    { $set: { available: false } }
  );
  await db.collection("carts").insertOne({
    userId: "cart-user",
    items: [{ menuItemId: SAMPLE_MENU._id, quantity: 1 }],
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  const items = await getRecommendations("cart-user");
  assert.ok(items.every((item) => item._id.toString() !== SAMPLE_MENU._id.toString()));
  assert.ok(items.every((item) => item.available !== false));
});

test("unauthorized update/delete is rejected", async () => {
  const db = getDb();
  const review = await db.collection("reviews").findOne({ userId: "user-1" });

  await assert.rejects(
    () => reviewService.updateReview("other-user", review._id.toString(), { rating: 4 }),
    (error) => error.statusCode === 403
  );

  await assert.rejects(
    () => reviewService.deleteReview("other-user", review._id.toString()),
    (error) => error.statusCode === 403
  );
});
