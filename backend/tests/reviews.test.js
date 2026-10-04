const test = require("node:test");
const assert = require("node:assert/strict");
const { ObjectId } = require("mongodb");

const mongodbPath = require.resolve("../src/config/mongodb");
const envPath = require.resolve("../src/config/env");
const reviewServicePath = require.resolve("../src/modules/reviews/review.service");
const orderServicePath = require.resolve("../src/modules/orders/order.service");
const paymentServicePath = require.resolve("../../payments/payment.service");

function setupTestEnvironment({
  users = [],
  menuItems = [],
  orders = [],
  reviews = [],
  payments = [],
  cartItems = [],
  cashfreeClientId = "TEST_CF_CLIENT_ID",
  cashfreeClientSecret = "TEST_CF_SECRET",
} = {}) {
  process.env.CASHFREE_CLIENT_ID = cashfreeClientId;
  process.env.CASHFREE_CLIENT_SECRET = cashfreeClientSecret;
  process.env.CASHFREE_ENV = "sandbox";

  delete require.cache[envPath];

  const usersMap = new Map();
  for (const u of users) usersMap.set(u.uid, u);

  const menuList = [...menuItems];
  const ordersMap = new Map();
  for (const o of orders) ordersMap.set(o._id.toString(), o);

  const reviewsList = [...reviews];
  const paymentsMap = new Map();
  for (const p of payments) {
    paymentsMap.set(p.cashfreeOrderId || p.razorpayOrderId || p._id.toString(), p);
  }

  const cartsMap = new Map();
  for (const u of users) {
    cartsMap.set(u.uid, { userId: u.uid, items: [...cartItems] });
  }

  const collections = {
    users: {
      findOne: async (q) => {
        if (q.uid) return usersMap.get(q.uid) || null;
        return null;
      },
    },
    menu: {
      findOne: async (q) => {
        return (
          menuList.find((m) => {
            if (q._id && m._id) return m._id.toString() === q._id.toString();
            if (q.name) {
              if (q.name instanceof RegExp) return q.name.test(m.name);
              if (q.name.$regex instanceof RegExp) return q.name.$regex.test(m.name);
              return m.name === q.name;
            }
            return false;
          }) || null
        );
      },
      find: (q) => ({
        toArray: async () => menuList,
      }),
    },
    carts: {
      findOne: async (q) => {
        if (q.userId) {
          if (!cartsMap.has(q.userId)) {
            cartsMap.set(q.userId, { userId: q.userId, items: [] });
          }
          return cartsMap.get(q.userId);
        }
        return null;
      },
      updateOne: async (q, u) => {
        const cart = cartsMap.get(q.userId) || { userId: q.userId, items: [] };
        if (u.$set && u.$set.items) cart.items = u.$set.items;
        cartsMap.set(q.userId, cart);
        return { acknowledged: true, modifiedCount: 1 };
      },
      insertOne: async (doc) => {
        cartsMap.set(doc.userId, doc);
        return { insertedId: new ObjectId(), acknowledged: true };
      },
    },
    orders: {
      insertOne: async (doc) => {
        const _id = doc._id || new ObjectId();
        const inserted = { _id, ...doc };
        ordersMap.set(_id.toString(), inserted);
        return { insertedId: _id, acknowledged: true };
      },
      findOne: async (q) => {
        if (q._id) {
          return ordersMap.get(q._id.toString()) || null;
        }
        if (q.$or && Array.isArray(q.$or)) {
          for (const sub of q.$or) {
            if (sub._id) {
              const res = ordersMap.get(sub._id.toString());
              if (res) return res;
            }
            if (sub.id) {
              for (const ord of ordersMap.values()) {
                if (String(ord.id) === String(sub.id) || String(ord._id) === String(sub.id)) return ord;
              }
            }
          }
        }
        return null;
      },
      find: (q) => ({
        toArray: async () => Array.from(ordersMap.values()),
        sort: () => ({
          toArray: async () => Array.from(ordersMap.values()),
        }),
      }),
    },
    reviews: {
      createIndex: async () => {},
      insertOne: async (doc) => {
        // Unique orderId check
        if (doc.orderId) {
          const duplicate = reviewsList.some(
            (r) => r.orderId && r.orderId.toString() === doc.orderId.toString()
          );
          if (duplicate) {
            const err = new Error("Duplicate review");
            err.code = 11000;
            throw err;
          }
        }
        const _id = doc._id || new ObjectId();
        const inserted = { _id, ...doc };
        reviewsList.push(inserted);
        return { insertedId: _id, acknowledged: true };
      },
      findOne: async (q) => {
        if (q.orderId) {
          return (
            reviewsList.find(
              (r) => r.orderId && r.orderId.toString() === q.orderId.toString()
            ) || null
          );
        }
        if (q.$or && Array.isArray(q.$or)) {
          for (const sub of q.$or) {
            if (sub.orderId) {
              const res = reviewsList.find(
                (r) => r.orderId && r.orderId.toString() === sub.orderId.toString()
              );
              if (res) return res;
            }
          }
        }
        return null;
      },
      find: (q = {}) => ({
        sort: () => ({
          toArray: async () => {
            let res = [...reviewsList];
            if (q.cafeteria) {
              if (q.cafeteria instanceof RegExp) {
                res = res.filter((r) => q.cafeteria.test(r.cafeteria));
              } else if (q.cafeteria.$regex) {
                const reg = new RegExp(q.cafeteria.$regex, "i");
                res = res.filter((r) => reg.test(r.cafeteria));
              } else {
                res = res.filter((r) => r.cafeteria === q.cafeteria);
              }
            }
            if (q.userId) {
              res = res.filter((r) => r.userId === q.userId);
            }
            return res;
          },
        }),
        toArray: async () => {
          let res = [...reviewsList];
          if (q.cafeteria) {
            if (q.cafeteria instanceof RegExp) {
              res = res.filter((r) => q.cafeteria.test(r.cafeteria));
            } else if (q.cafeteria.$regex) {
              const reg = new RegExp(q.cafeteria.$regex, "i");
              res = res.filter((r) => reg.test(r.cafeteria));
            } else {
              res = res.filter((r) => r.cafeteria === q.cafeteria);
            }
          }
          return res;
        },
      }),
    },
    payments: {
      createIndex: async () => {},
      insertOne: async (doc) => {
        const _id = doc._id || new ObjectId();
        const inserted = { _id, ...doc };
        paymentsMap.set(doc.cashfreeOrderId || doc.razorpayOrderId || _id.toString(), inserted);
        return { insertedId: _id, acknowledged: true };
      },
      findOne: async (q) => {
        if (q.cashfreeOrderId) return paymentsMap.get(q.cashfreeOrderId) || null;
        if (q.razorpayOrderId) return paymentsMap.get(q.razorpayOrderId) || null;
        if (q._id) {
          for (const val of paymentsMap.values()) {
            if (val._id && val._id.toString() === q._id.toString()) return val;
          }
        }
        return null;
      },
      updateOne: async (q, u) => {
        let rec = null;
        if (q.cashfreeOrderId) rec = paymentsMap.get(q.cashfreeOrderId);
        if (!rec && q._id) {
          for (const val of paymentsMap.values()) {
            if (val._id && val._id.toString() === q._id.toString()) {
              rec = val;
              break;
            }
          }
        }
        if (rec && u.$set) {
          Object.assign(rec, u.$set);
          return { acknowledged: true, modifiedCount: 1 };
        }
        return { acknowledged: true, modifiedCount: 0 };
      },
    },
  };

  require.cache[mongodbPath] = {
    exports: {
      getDb: () => ({
        collection: (name) => collections[name],
      }),
    },
  };

  delete require.cache[reviewServicePath];
  delete require.cache[orderServicePath];
  delete require.cache[paymentServicePath];

  const reviewService = require(reviewServicePath);
  const orderService = require(orderServicePath);
  const paymentService = require(paymentServicePath);

  return {
    reviewService,
    orderService,
    paymentService,
    collections,
    reviewsList,
    ordersMap,
    paymentsMap,
    cartsMap,
  };
}

const SAMPLE_MENU_ITEM = {
  _id: new ObjectId(),
  name: "Masala Dosa",
  price: 60,
  cafeteria: "Bengaluru Cafe",
  available: true,
};

const SAMPLE_STUDENT = {
  uid: "student-user-1",
  role: "Student",
  name: "Alice Student",
  status: "ACTIVE",
};

const SAMPLE_STUDENT_2 = {
  uid: "student-user-2",
  role: "Student",
  name: "Bob Student",
  status: "ACTIVE",
};

const SAMPLE_FACULTY = {
  uid: "faculty-user-1",
  role: "Faculty",
  name: "Dr. Carol Faculty",
  status: "ACTIVE",
};

// ============================================================
// FEATURE 1: FLAT ₹3 GST TESTS
// ============================================================

test("1. ₹3 GST is added to a normal order", async () => {
  const { orderService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    menuItems: [SAMPLE_MENU_ITEM],
    cartItems: [{ menuItemId: SAMPLE_MENU_ITEM._id, quantity: 1 }],
  });

  const order = await orderService.createOrder("student-user-1", "No spice");

  assert.equal(order.subtotal, 60);
  assert.equal(order.gst, 3);
  assert.equal(order.pickupFee, 0);
  assert.equal(order.total, 63);
  assert.equal(order.totalAmount, 63);
});

test("2. ₹3 GST is added to a scheduled order", async () => {
  const { orderService } = setupTestEnvironment({
    users: [SAMPLE_FACULTY],
    menuItems: [SAMPLE_MENU_ITEM],
    cartItems: [{ menuItemId: SAMPLE_MENU_ITEM._id, quantity: 2 }], // 60 * 2 = 120
  });

  const futureTime = new Date(Date.now() + 30 * 60 * 1000).toISOString();

  const scheduledOrder = await orderService.createOrder(
    "faculty-user-1",
    "Scheduled pickup",
    [],
    {
      orderType: "SCHEDULED",
      scheduledPickupAt: futureTime,
    }
  );

  assert.equal(scheduledOrder.subtotal, 120);
  assert.equal(scheduledOrder.gst, 3);
  assert.equal(scheduledOrder.pickupFee, 0);
  assert.equal(scheduledOrder.total, 123);
  assert.equal(scheduledOrder.totalAmount, 123);
  assert.equal(scheduledOrder.orderType, "SCHEDULED");
});

test("3. GST is included in Cashfree amount", async () => {
  const { paymentService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    menuItems: [SAMPLE_MENU_ITEM],
    cartItems: [{ menuItemId: SAMPLE_MENU_ITEM._id, quantity: 1 }], // 60
  });

  paymentService.setCustomFetch(async (url, opts) => {
    const payload = JSON.parse(opts.body);
    return {
      ok: true,
      status: 200,
      json: async () => ({
        cf_order_id: "cf_gst_123",
        order_id: payload.order_id,
        order_amount: payload.order_amount,
        payment_session_id: "session_gst_xyz",
      }),
    };
  });

  const paymentOrder = await paymentService.createPaymentOrder("student-user-1");

  assert.equal(paymentOrder.subtotal, 60);
  assert.equal(paymentOrder.gst, 3);
  assert.equal(paymentOrder.totalAmount, 63);
  assert.equal(paymentOrder.amount, 63);
  assert.equal(paymentOrder.amountPaise, 6300);
});

test("4. GST is not duplicated during payment verification", async () => {
  const cfOrderId = "order_cf_no_dup_gst";
  const { paymentService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-user-1",
        gateway: "CASHFREE",
        cashfreeOrderId: cfOrderId,
        subtotal: 60,
        itemsTotal: 60,
        gst: 3,
        pickupFee: 0,
        amount: 63,
        amountPaise: 6300,
        currency: "INR",
        status: "CREATED",
        campusEatsOrderId: null,
        itemsSnapshot: [
          {
            menuItemId: SAMPLE_MENU_ITEM._id,
            name: SAMPLE_MENU_ITEM.name,
            price: 60,
            quantity: 1,
            subtotal: 60,
          },
        ],
        cafeteria: "Bengaluru Cafe",
        createdAt: new Date(),
        updatedAt: new Date(),
      },
    ],
  });

  paymentService.setCustomFetch(async () => ({
    ok: true,
    status: 200,
    json: async () => ({
      order_id: cfOrderId,
      order_amount: 63.0,
      order_status: "PAID",
      cf_order_id: "cf_verified_123",
    }),
  }));

  const verification = await paymentService.verifyPayment("student-user-1", {
    cashfreeOrderId: cfOrderId,
  });

  assert.equal(verification.order.subtotal, 60);
  assert.equal(verification.order.gst, 3);
  assert.equal(verification.order.pickupFee, 0);
  assert.equal(verification.order.total, 63);
  assert.equal(verification.order.totalAmount, 63);
});

// ============================================================
// FEATURE 2: RATING AND REVIEW TESTS
// ============================================================

test("5. Student can submit a review after collection", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        userType: "Student",
        studentName: "Alice Student",
        cafeteria: "Bengaluru Cafe",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 63,
        items: [{ menuItemId: SAMPLE_MENU_ITEM._id, name: SAMPLE_MENU_ITEM.name, quantity: 1 }],
      },
    ],
  });

  const review = await reviewService.createOrderReview({
    userId: "student-user-1",
    userRole: "Student",
    orderId: orderId.toString(),
    rating: 5,
    review: "Food was hot and delicious!",
  });

  assert.equal(review.userId, "student-user-1");
  assert.equal(review.userRole, "Student");
  assert.equal(review.rating, 5);
  assert.equal(review.review, "Food was hot and delicious!");
  assert.equal(review.cafeteria, "Bengaluru Cafe");
});

test("6. Faculty can submit a review after collection", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_FACULTY],
    orders: [
      {
        _id: orderId,
        userId: "faculty-user-1",
        userRole: "Faculty",
        userType: "Faculty",
        studentName: "Dr. Carol Faculty",
        cafeteria: "Bengaluru Cafe",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 123,
        items: [{ menuItemId: SAMPLE_MENU_ITEM._id, name: SAMPLE_MENU_ITEM.name, quantity: 2 }],
      },
    ],
  });

  const review = await reviewService.createOrderReview({
    userId: "faculty-user-1",
    userRole: "Faculty",
    orderId: orderId.toString(),
    rating: 4,
    review: "Fresh food, nicely packed.",
  });

  assert.equal(review.userId, "faculty-user-1");
  assert.equal(review.userRole, "Faculty");
  assert.equal(review.rating, 4);
  assert.equal(review.review, "Fresh food, nicely packed.");
});

test("7. Student cannot review before collection", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        status: "PREPARING",
        pickupStatus: "PREPARING",
        total: 63,
      },
    ],
  });

  await assert.rejects(
    () =>
      reviewService.createOrderReview({
        userId: "student-user-1",
        userRole: "Student",
        orderId: orderId.toString(),
        rating: 5,
        review: "Early review attempt",
      }),
    (err) =>
      err.statusCode === 400 &&
      err.message.includes("collected")
  );
});

test("8. Faculty cannot review before collection", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_FACULTY],
    orders: [
      {
        _id: orderId,
        userId: "faculty-user-1",
        userRole: "Faculty",
        status: "Ready",
        pickupStatus: "READY",
        total: 123,
      },
    ],
  });

  await assert.rejects(
    () =>
      reviewService.createOrderReview({
        userId: "faculty-user-1",
        userRole: "Faculty",
        orderId: orderId.toString(),
        rating: 5,
        review: "Ready but uncollected",
      }),
    (err) =>
      err.statusCode === 400 &&
      err.message.includes("collected")
  );
});

test("9. Cancelled order cannot be reviewed", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        status: "CANCELLED",
        pickupStatus: "NOT_SCHEDULED",
        total: 63,
      },
    ],
  });

  await assert.rejects(
    () =>
      reviewService.createOrderReview({
        userId: "student-user-1",
        userRole: "Student",
        orderId: orderId.toString(),
        rating: 1,
        review: "Order was cancelled",
      }),
    (err) =>
      err.statusCode === 400 &&
      err.message.includes("Cancelled orders cannot be reviewed")
  );
});

test("10. User cannot review another user's order", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT, SAMPLE_STUDENT_2],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 63,
      },
    ],
  });

  await assert.rejects(
    () =>
      reviewService.createOrderReview({
        userId: "student-user-2", // User 2 attempting to review User 1's order
        userRole: "Student",
        orderId: orderId.toString(),
        rating: 5,
      }),
    (err) =>
      err.statusCode === 403 &&
      err.message.includes("You can only review your own orders")
  );
});

test("11. Duplicate review is rejected", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT_2],
    orders: [
      {
        _id: orderId,
        userId: "student-user-2",
        userRole: "Student",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 63,
      },
    ],
  });

  await reviewService.createOrderReview({
    userId: "student-user-2",
    userRole: "Student",
    orderId: orderId.toString(),
    rating: 4,
    review: "Good food",
  });

  await assert.rejects(
    () =>
      reviewService.createOrderReview({
        userId: "student-user-2",
        userRole: "Student",
        orderId: orderId.toString(),
        rating: 5,
        review: "Trying to review again",
      }),
    (err) =>
      err.statusCode === 409 &&
      err.message.includes("already reviewed")
  );
});

test("12. Rating outside 1–5 is rejected", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 63,
      },
    ],
  });

  for (const badRating of [0, 6, -1, 3.5, "five"]) {
    await assert.rejects(
      () =>
        reviewService.createOrderReview({
          userId: "student-user-1",
          userRole: "Student",
          orderId: orderId.toString(),
          rating: badRating,
        }),
      (err) =>
        err.statusCode === 400 &&
        err.message.includes("rating must be an integer from 1 to 5")
    );
  }
});

test("13. Review text remains optional", async () => {
  const orderId = new ObjectId();
  const { reviewService } = setupTestEnvironment({
    users: [SAMPLE_STUDENT],
    orders: [
      {
        _id: orderId,
        userId: "student-user-1",
        userRole: "Student",
        status: "COMPLETED",
        pickupStatus: "COLLECTED",
        total: 63,
      },
    ],
  });

  const review = await reviewService.createOrderReview({
    userId: "student-user-1",
    userRole: "Student",
    orderId: orderId.toString(),
    rating: 5,
    // review omitted
  });

  assert.equal(review.rating, 5);
  assert.equal(review.review, "");
});

test("14. Cafeteria average rating is calculated correctly", async () => {
  const cafeteria = "Bengaluru Cafe";
  const { reviewService } = setupTestEnvironment({
    reviews: [
      {
        orderId: new ObjectId(),
        userId: "user-a",
        cafeteria,
        rating: 5,
        review: "Amazing",
      },
      {
        orderId: new ObjectId(),
        userId: "user-b",
        cafeteria,
        rating: 4,
        review: "Good",
      },
      {
        orderId: new ObjectId(),
        userId: "user-c",
        cafeteria,
        rating: 3,
        review: "Average",
      },
    ],
  });

  const summary = await reviewService.getCafeteriaRatingSummary(cafeteria);
  assert.equal(summary.cafeteria, "Bengaluru Cafe");
  assert.equal(summary.ratingCount, 3);
  assert.equal(summary.averageRating, 4.0);
  assert.equal(summary.distribution[5], 1);
  assert.equal(summary.distribution[4], 1);
  assert.equal(summary.distribution[3], 1);
  assert.equal(summary.distribution[2], 0);
  assert.equal(summary.distribution[1], 0);
});

test("15. Admin can only access reviews for their assigned cafeteria", async () => {
  const { reviewService } = setupTestEnvironment({
    reviews: [
      {
        orderId: new ObjectId(),
        userId: "user-a",
        cafeteria: "Bengaluru Cafe",
        rating: 5,
        review: "Great dosa",
      },
    ],
  });

  const bengaluruAdmin = {
    role: "Admin",
    cafeteria: "Bengaluru Cafe",
  };

  const reviews = await reviewService.getCafeteriaReviews(
    "Bengaluru Cafe",
    bengaluruAdmin
  );
  assert.ok(Array.isArray(reviews));
  assert.equal(reviews.length, 1);

  // Bengaluru Cafe admin attempting to access Cafe PESU reviews
  await assert.rejects(
    () =>
      reviewService.getCafeteriaReviews("Cafe PESU", bengaluruAdmin),
    (err) =>
      err.statusCode === 403 &&
      err.message.includes("assigned cafeteria")
  );
});
