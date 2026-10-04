const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const test = require("node:test");
const { ObjectId } = require("mongodb");

const envPath = require.resolve("../src/config/env");
const mongodbPath = require.resolve("../src/config/mongodb");
const cartServicePath = require.resolve("../src/modules/cart/cart.service");
const paymentServicePath = require.resolve("../../payments/payment.service");

function makeResponse() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(value) {
      this.body = value;
      return this;
    },
  };
}

function setupTestEnvironment({
  user = { uid: "student-123", role: "Student", status: "ACTIVE" },
  cartItems = [],
  menuItems = [],
  orders = [],
  payments = [],
  cashfreeClientId,
  cashfreeClientSecret,
  cashfreeEnv = "sandbox",
} = {}) {
  process.env.RAZORPAY_KEY_ID = "rzp_test_key123";
  process.env.RAZORPAY_KEY_SECRET = "test_razorpay_secret_456";
  process.env.RAZORPAY_WEBHOOK_SECRET = "test_webhook_secret_789";

  if (cashfreeClientId) {
    process.env.CASHFREE_CLIENT_ID = cashfreeClientId;
  } else {
    process.env.CASHFREE_CLIENT_ID = "";
  }

  if (cashfreeClientSecret) {
    process.env.CASHFREE_CLIENT_SECRET = cashfreeClientSecret;
  } else {
    process.env.CASHFREE_CLIENT_SECRET = "";
  }
  process.env.CASHFREE_ENV = cashfreeEnv;

  delete require.cache[envPath];

  const paymentsMap = new Map();
  for (const p of payments) {
    paymentsMap.set(p.cashfreeOrderId || p.razorpayOrderId || p._id.toString(), p);
  }

  const ordersMap = new Map();
  for (const o of orders) {
    ordersMap.set(o._id.toString(), o);
  }

  const userCart = {
    userId: user.uid,
    items: cartItems,
  };

  const collections = {
    users: {
      findOne: async (q) => (q.uid === user.uid ? user : null),
    },
    carts: {
      findOne: async (q) => (q.userId === user.uid ? userCart : null),
      updateOne: async (q, u) => {
        if (u.$set && u.$set.items) {
          userCart.items = u.$set.items;
        }
        return { acknowledged: true, modifiedCount: 1 };
      },
    },
    menu: {
      findOne: async (q) => {
        return (
          menuItems.find((m) => {
            if (q._id && m._id) return m._id.toString() === q._id.toString();
            if (q.name) {
              if (q.name instanceof RegExp) return q.name.test(m.name);
              if (q.name.$regex instanceof RegExp) return q.name.$regex.test(m.name);
              return m.name === q.name;
            }
            if (q.$or && Array.isArray(q.$or)) {
              return q.$or.some((subQ) => {
                if (subQ.id && (m.id === subQ.id || m._id?.toString() === subQ.id)) return true;
                if (subQ.menuItemId && (m.menuItemId === subQ.menuItemId || m._id?.toString() === subQ.menuItemId)) return true;
                return false;
              });
            }
            return false;
          }) || null
        );
      },
    },
    orders: {
      insertOne: async (doc) => {
        const _id = new ObjectId();
        const inserted = { _id, ...doc };
        ordersMap.set(_id.toString(), inserted);
        return { insertedId: _id, acknowledged: true };
      },
      findOne: async (q) => {
        if (q._id) return ordersMap.get(q._id.toString()) || null;
        return null;
      },
    },
    payments: {
      createIndex: async () => {},
      insertOne: async (doc) => {
        const _id = new ObjectId();
        const inserted = { _id, ...doc };
        paymentsMap.set(doc.cashfreeOrderId || doc.razorpayOrderId, inserted);
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
        if (!rec && q.razorpayOrderId) rec = paymentsMap.get(q.razorpayOrderId);
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

  delete require.cache[cartServicePath];
  delete require.cache[paymentServicePath];
  const paymentService = require(paymentServicePath);

  // Mock Razorpay Client
  const mockRazorpayClient = {
    orders: {
      create: async (params) => ({
        id: `order_${Date.now()}_mock`,
        amount: params.amount,
        currency: params.currency,
        receipt: params.receipt,
        status: "created",
      }),
    },
    payments: {
      fetch: async (paymentId) => ({
        id: paymentId,
        order_id: paymentId.replace("pay_", "order_"),
        amount: 10000,
        currency: "INR",
        status: "captured",
      }),
    },
  };

  paymentService.setRazorpayClient(mockRazorpayClient);

  return {
    paymentService,
    collections,
    mockRazorpayClient,
    userCart,
    ordersMap,
    paymentsMap,
  };
}

test("1. create-order requires authentication middleware", () => {
  const authMiddleware =
    require("../src/middleware/auth.middleware").authenticate;
  const req = { headers: {} };
  const res = makeResponse();
  let nextCalled = false;

  authMiddleware(req, res, () => {
    nextCalled = true;
  });

  assert.equal(res.statusCode, 401);
  assert.equal(nextCalled, false);
});

test("2. create-order requires ACTIVE student account", async () => {
  for (const status of ["GRADUATED", "SUSPENDED", "INACTIVE"]) {
    const { paymentService } = setupTestEnvironment({
      user: {
        uid: `student-${status.toLowerCase()}`,
        role: "Student",
        status,
      },
    });

    await assert.rejects(
      paymentService.createPaymentOrder(`student-${status.toLowerCase()}`),
      (err) => err.statusCode === 403
    );
  }
});

test("3. empty cart is rejected with 400 Bad Request", async () => {
  const { paymentService } = setupTestEnvironment({
    cartItems: [],
  });

  await assert.rejects(
    paymentService.createPaymentOrder("student-123"),
    (err) => err.statusCode === 400 && err.message.includes("empty")
  );
});

test("4. unavailable or missing menu item is rejected with 400", async () => {
  const missingItemId = new ObjectId();
  const unavailableItemId = new ObjectId();

  const { paymentService: missingService } = setupTestEnvironment({
    cartItems: [{ menuItemId: missingItemId, quantity: 1 }],
    menuItems: [],
  });

  await assert.rejects(
    missingService.createPaymentOrder("student-123"),
    (err) => err.statusCode === 400 && err.message.includes("no longer exist")
  );

  const { paymentService: unavailService } = setupTestEnvironment({
    cartItems: [{ menuItemId: unavailableItemId, quantity: 1 }],
    menuItems: [
      {
        _id: unavailableItemId,
        name: "Sold Out Snack",
        price: 50,
        available: false,
      },
    ],
  });

  await assert.rejects(
    unavailService.createPaymentOrder("student-123"),
    (err) => err.statusCode === 400 && err.message.includes("unavailable")
  );
});

test("5. client-provided amount cannot override server authoritative calculation", async () => {
  const itemId = new ObjectId();
  const { paymentService } = setupTestEnvironment({
    cartItems: [{ menuItemId: itemId, quantity: 2 }],
    menuItems: [
      {
        _id: itemId,
        name: "Masala Dosa",
        price: 60,
        available: true,
      },
    ],
  });

  // Server calculation: 2 * 60 + 3 GST = 123 INR = 12300 paise
  const orderResult = await paymentService.createPaymentOrder("student-123");
  assert.equal(orderResult.amount, 12300);
  assert.equal(orderResult.currency, "INR");
});

test("6. Razorpay order is created using server-calculated amount in paise", async () => {
  const itemId = new ObjectId();
  let createdParams = null;
  const { paymentService, mockRazorpayClient } = setupTestEnvironment({
    cartItems: [{ menuItemId: itemId, quantity: 3 }],
    menuItems: [
      {
        _id: itemId,
        name: "Coffee",
        price: 25,
        available: true,
      },
    ],
  });

  mockRazorpayClient.orders.create = async (params) => {
    createdParams = params;
    return {
      id: "order_test_server_calc",
      amount: params.amount,
      currency: params.currency,
      receipt: params.receipt,
      status: "created",
    };
  };

  const result = await paymentService.createPaymentOrder("student-123");
  assert.equal(result.razorpayOrderId, "order_test_server_calc");
  assert.equal(result.amount, 7800); // 3 * 25 + 3 GST = 78 INR = 7800 paise
  assert.equal(createdParams.amount, 7800);
});

test("7. Key Secret is never returned in create-order response", async () => {
  const itemId = new ObjectId();
  const { paymentService } = setupTestEnvironment({
    cartItems: [{ menuItemId: itemId, quantity: 1 }],
    menuItems: [
      {
        _id: itemId,
        name: "Vada",
        price: 30,
        available: true,
      },
    ],
  });

  const result = await paymentService.createPaymentOrder("student-123");
  assert.equal(result.keyId, "rzp_test_key123");
  assert.equal(result.keySecret, undefined);
  assert.equal(
    JSON.stringify(result).includes("test_razorpay_secret"),
    false
  );
});

test("8. invalid payment signature is rejected with 400", async () => {
  const { paymentService, paymentsMap } = setupTestEnvironment({
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        razorpayOrderId: "order_sig_test",
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
        campusEatsOrderId: null,
        itemsSnapshot: [{ name: "Meals", price: 100, quantity: 1 }],
      },
    ],
  });

  await assert.rejects(
    paymentService.verifyPayment("student-123", {
      razorpayOrderId: "order_sig_test",
      razorpayPaymentId: "pay_test_123",
      razorpaySignature: "invalid_tampered_signature_hex",
    }),
    (err) => err.statusCode === 400 && err.message.includes("signature")
  );

  const updatedRecord = paymentsMap.get("order_sig_test");
  assert.equal(updatedRecord.status, "FAILED");
});

test("9. payment for another user's Razorpay order is rejected", async () => {
  const { paymentService } = setupTestEnvironment({
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-OTHER-USER",
        razorpayOrderId: "order_other_user",
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
      },
    ],
  });

  await assert.rejects(
    paymentService.verifyPayment("student-123", {
      razorpayOrderId: "order_other_user",
      razorpayPaymentId: "pay_xyz",
      razorpaySignature: "dummy",
    }),
    (err) => err.statusCode === 403
  );
});

test("10. payment amount or currency mismatch with Razorpay record is rejected", async () => {
  const secret = "test_razorpay_secret_456";
  const orderId = "order_mismatch";
  const paymentId = "pay_mismatch";
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  const { paymentService, mockRazorpayClient } = setupTestEnvironment({
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        razorpayOrderId: orderId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
        itemsSnapshot: [{ name: "Meals", price: 100, quantity: 1 }],
      },
    ],
  });

  // Return amount mismatch from Razorpay API
  mockRazorpayClient.payments.fetch = async () => ({
    id: paymentId,
    order_id: orderId,
    amount: 5000, // 50 INR instead of 100 INR
    currency: "INR",
  });

  await assert.rejects(
    paymentService.verifyPayment("student-123", {
      razorpayOrderId: orderId,
      razorpayPaymentId: paymentId,
      razorpaySignature: signature,
    }),
    (err) => err.statusCode === 400 && err.message.includes("mismatch")
  );
});

test("11. duplicate payment verification does not create duplicate CampusEATS orders", async () => {
  const secret = "test_razorpay_secret_456";
  const orderId = "order_duplicate_test";
  const paymentId = "pay_duplicate_test";
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  const existingOrderId = new ObjectId();
  const { paymentService, ordersMap } = setupTestEnvironment({
    orders: [
      {
        _id: existingOrderId,
        userId: "student-123",
        total: 100,
        status: "PENDING",
      },
    ],
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CAPTURED",
        campusEatsOrderId: existingOrderId,
      },
    ],
  });

  const countBefore = ordersMap.size;
  const result = await paymentService.verifyPayment("student-123", {
    razorpayOrderId: orderId,
    razorpayPaymentId: paymentId,
    razorpaySignature: signature,
  });

  assert.equal(ordersMap.size, countBefore);
  assert.equal(result.order._id.toString(), existingOrderId.toString());
  assert.equal(result.isExisting, true);
});

test("12. successful verified payment creates and links exactly one CampusEATS order", async () => {
  const secret = "test_razorpay_secret_456";
  const orderId = "order_success_123";
  const paymentId = "pay_success_123";
  const signature = crypto
    .createHmac("sha256", secret)
    .update(`${orderId}|${paymentId}`)
    .digest("hex");

  const paymentDocId = new ObjectId();
  const {
    paymentService,
    ordersMap,
    paymentsMap,
    mockRazorpayClient,
    userCart,
  } = setupTestEnvironment({
    cartItems: [{ menuItemId: new ObjectId(), quantity: 1 }],
    payments: [
      {
        _id: paymentDocId,
        userId: "student-123",
        razorpayOrderId: orderId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
        campusEatsOrderId: null,
        itemsSnapshot: [
          { name: "Meals", price: 100, quantity: 1, subtotal: 100 },
        ],
      },
    ],
  });

  mockRazorpayClient.payments.fetch = async () => ({
    id: paymentId,
    order_id: orderId,
    amount: 10000,
    currency: "INR",
    status: "captured",
  });

  const result = await paymentService.verifyPayment("student-123", {
    razorpayOrderId: orderId,
    razorpayPaymentId: paymentId,
    razorpaySignature: signature,
  });

  assert.ok(result.order);
  assert.equal(result.order.userId, "student-123");
  assert.equal(result.order.paymentStatus, "Paid");
  assert.equal(result.order.razorpayPaymentId, paymentId);
  assert.equal(ordersMap.size, 1);

  const updatedPayment = paymentsMap.get(orderId);
  assert.equal(updatedPayment.status, "CAPTURED");
  assert.equal(
    updatedPayment.campusEatsOrderId.toString(),
    result.order._id.toString()
  );

  // User cart is cleared
  assert.equal(userCart.items.length, 0);
});

test("13. webhook with invalid signature is rejected with 400", async () => {
  const { paymentService } = setupTestEnvironment();

  const rawBody = JSON.stringify({ event: "payment.captured" });
  const badSignature = "invalid_signature_hex";

  await assert.rejects(
    paymentService.handleWebhook(rawBody, badSignature),
    (err) => err.statusCode === 400 && err.message.includes("signature")
  );
});

test("14. repeated valid webhook is idempotent", async () => {
  const webhookSecret = "test_webhook_secret_789";
  const orderId = "order_webhook_test";
  const paymentId = "pay_webhook_test";

  const eventPayload = {
    event: "payment.captured",
    payload: {
      payment: {
        entity: {
          id: paymentId,
          order_id: orderId,
          amount: 10000,
          currency: "INR",
          status: "captured",
        },
      },
    },
  };

  const rawBody = JSON.stringify(eventPayload);
  const signature = crypto
    .createHmac("sha256", webhookSecret)
    .update(rawBody)
    .digest("hex");

  const existingOrderId = new ObjectId();
  const { paymentService, paymentsMap, ordersMap } = setupTestEnvironment({
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        razorpayOrderId: orderId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CAPTURED",
        campusEatsOrderId: existingOrderId,
      },
    ],
  });

  const ordersCountBefore = ordersMap.size;
  const result = await paymentService.handleWebhook(rawBody, signature);

  assert.equal(result.received, true);
  assert.equal(result.status, "already_captured");
  assert.equal(ordersMap.size, ordersCountBefore);
});

test("15. direct unpaid POST /api/orders route is blocked", async () => {
  const orderController = require("../src/modules/orders/order.controller");
  const req = { user: { uid: "student-123" }, body: {} };
  const res = makeResponse();

  await orderController.createOrder(req, res, () => {});

  assert.equal(res.statusCode, 400);
  assert.equal(res.body.code, "PAYMENT_REQUIRED");
});

test("16. Cashfree Sandbox create-order returns paymentSessionId with server calculated amount", async () => {
  const itemId = new ObjectId();
  const { paymentService } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_CLIENT_SECRET",
    cashfreeEnv: "sandbox",
    cartItems: [{ menuItemId: itemId, quantity: 2 }],
    menuItems: [
      {
        _id: itemId,
        name: "Veg Thali",
        price: 80,
        available: true,
      },
    ],
  });

  let requestedUrl = null;
  let requestedPayload = null;

  paymentService.setCustomFetch(async (url, opts) => {
    requestedUrl = url;
    requestedPayload = JSON.parse(opts.body);
    return {
      ok: true,
      status: 200,
      json: async () => ({
        cf_order_id: "cf_12345",
        order_id: requestedPayload.order_id,
        order_amount: requestedPayload.order_amount,
        order_currency: "INR",
        payment_session_id: "session_mock_token_abc123",
        order_status: "ACTIVE",
      }),
    };
  });

  const result = await paymentService.createPaymentOrder("student-123", "No onions", "South Mess");
  assert.equal(result.paymentGateway, "CASHFREE");
  assert.equal(result.paymentSessionId, "session_mock_token_abc123");
  assert.equal(result.amount, 163);
  assert.equal(result.currency, "INR");
  assert.equal(result.environment, "sandbox");
  assert.equal(requestedUrl.includes("sandbox.cashfree.com/pg/orders"), true);
  assert.equal(requestedPayload.order_amount, 163);
});

test("17. Cashfree create-order does not expose CASHFREE_CLIENT_SECRET in response", async () => {
  const itemId = new ObjectId();
  const { paymentService } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET_MUST_NOT_LEAK",
    cartItems: [{ menuItemId: itemId, quantity: 1 }],
    menuItems: [{ _id: itemId, name: "Tea", price: 15, available: true }],
  });

  paymentService.setCustomFetch(async (url, opts) => ({
    ok: true,
    status: 200,
    json: async () => ({
      cf_order_id: "cf_tea",
      order_id: "order_tea_123",
      payment_session_id: "session_tea",
    }),
  }));

  const result = await paymentService.createPaymentOrder("student-123");
  assert.equal(result.clientSecret, undefined);
  assert.equal(
    JSON.stringify(result).includes("TEST_CF_SECRET_MUST_NOT_LEAK"),
    false
  );
});

test("18. Cashfree payment verification checks PAID status, creates order and clears cart", async () => {
  const orderId = "order_cf_verify_test";
  const { paymentService, ordersMap, paymentsMap, userCart } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    cartItems: [{ menuItemId: new ObjectId(), quantity: 1 }],
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        gateway: "CASHFREE",
        cashfreeOrderId: orderId,
        amount: 150,
        amountPaise: 15000,
        currency: "INR",
        status: "CREATED",
        itemsSnapshot: [{ name: "Biryani", price: 150, quantity: 1, subtotal: 150 }],
        cafeteria: "Bengaluru Cafe",
      },
    ],
  });

  paymentService.setCustomFetch(async (url) => {
    assert.equal(url.includes(`/orders/${orderId}`), true);
    return {
      ok: true,
      status: 200,
      json: async () => ({
        cf_order_id: "cf_order_biryani",
        order_id: orderId,
        order_amount: 150.0,
        order_currency: "INR",
        order_status: "PAID",
      }),
    };
  });

  const result = await paymentService.verifyPayment("student-123", {
    cashfreeOrderId: orderId,
  });

  assert.ok(result.order);
  assert.equal(result.order.userId, "student-123");
  assert.equal(result.order.paymentStatus, "Paid");
  assert.equal(result.order.cashfreeOrderId, orderId);
  assert.equal(ordersMap.size, 1);
  assert.equal(userCart.items.length, 0);

  const updatedPayment = paymentsMap.get(orderId);
  assert.equal(updatedPayment.status, "CAPTURED");
  assert.equal(updatedPayment.campusEatsOrderId.toString(), result.order._id.toString());
});

test("19. Cashfree payment verification rejects non-PAID order status", async () => {
  const orderId = "order_cf_pending";
  const { paymentService, paymentsMap } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        gateway: "CASHFREE",
        cashfreeOrderId: orderId,
        amount: 50,
        amountPaise: 5000,
        currency: "INR",
        status: "CREATED",
        itemsSnapshot: [{ name: "Samosa", price: 50, quantity: 1 }],
      },
    ],
  });

  paymentService.setCustomFetch(async () => ({
    ok: true,
    status: 200,
    json: async () => ({
      order_id: orderId,
      order_amount: 50.0,
      order_status: "ACTIVE", // Student didn't finish payment in modal
    }),
  }));

  await assert.rejects(
    paymentService.verifyPayment("student-123", { cashfreeOrderId: orderId }),
    (err) => err.statusCode === 400 && err.message.includes("not been completed")
  );

  const paymentRecord = paymentsMap.get(orderId);
  assert.equal(paymentRecord.status, "FAILED");
});

test("20. Cashfree payment verification rejects amount mismatch", async () => {
  const orderId = "order_cf_amount_mismatch";
  const { paymentService } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        gateway: "CASHFREE",
        cashfreeOrderId: orderId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
        itemsSnapshot: [{ name: "Sandwich", price: 100, quantity: 1 }],
      },
    ],
  });

  paymentService.setCustomFetch(async () => ({
    ok: true,
    status: 200,
    json: async () => ({
      order_id: orderId,
      order_amount: 50.0, // Amount mismatch
      order_status: "PAID",
    }),
  }));

  await assert.rejects(
    paymentService.verifyPayment("student-123", { cashfreeOrderId: orderId }),
    (err) => err.statusCode === 400 && err.message.includes("mismatch")
  );
});

test("21. create-order auto-syncs cart from authoritative menu if items payload is supplied", async () => {
  const itemId = new ObjectId();
  const { paymentService, userCart } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    cartItems: [], // initially empty MongoDB cart
    menuItems: [
      {
        _id: itemId,
        name: "Paneer Roll",
        price: 90,
        available: true,
      },
    ],
  });

  paymentService.setCustomFetch(async (url, opts) => {
    const payload = JSON.parse(opts.body);
    return {
      ok: true,
      status: 200,
      json: async () => ({
        cf_order_id: "cf_roll_123",
        order_id: payload.order_id,
        order_amount: payload.order_amount,
        payment_session_id: "session_roll_abc",
      }),
    };
  });

  const result = await paymentService.createPaymentOrder(
    "student-123",
    "",
    "Bengaluru Cafe",
    [{ menuItemId: itemId, quantity: 2 }]
  );

  assert.equal(result.paymentGateway, "CASHFREE");
  assert.equal(result.amount, 183); // 2 * 90 + 3 GST = 183
  assert.equal(userCart.items.length, 1);
  assert.equal(userCart.items[0].quantity, 2);
});

test("22. MongoDB cart is NOT cleared on unverified or failed payment", async () => {
  const itemId = new ObjectId();
  const orderId = "order_cf_fail_retain_cart";
  const { paymentService, userCart, paymentsMap } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    cartItems: [{ menuItemId: itemId, quantity: 2 }],
    payments: [
      {
        _id: new ObjectId(),
        userId: "student-123",
        gateway: "CASHFREE",
        cashfreeOrderId: orderId,
        amount: 100,
        amountPaise: 10000,
        currency: "INR",
        status: "CREATED",
        itemsSnapshot: [{ name: "Snack", price: 50, quantity: 2 }],
      },
    ],
  });

  paymentService.setCustomFetch(async () => ({
    ok: true,
    status: 200,
    json: async () => ({
      order_id: orderId,
      order_amount: 100.0,
      order_status: "FAILED",
    }),
  }));

  await assert.rejects(
    paymentService.verifyPayment("student-123", { cashfreeOrderId: orderId }),
    (err) => err.statusCode === 400
  );

  // Cart must remain completely intact
  assert.equal(userCart.items.length, 1);
  assert.equal(userCart.items[0].quantity, 2);
  assert.equal(paymentsMap.get(orderId).status, "FAILED");
});

test("23. Regression: non-empty cart with client items (e.g. Masala Dosa, ₹60) successfully reaches Cashfree payment order creation", async () => {
  const { paymentService, userCart } = setupTestEnvironment({
    cashfreeClientId: "TEST_CF_CLIENT_ID",
    cashfreeClientSecret: "TEST_CF_SECRET",
    cartItems: [], // initially empty MongoDB cart before sync
    menuItems: [
      {
        _id: new ObjectId(),
        name: "Masala Dosa",
        price: 60,
        category: "South Indian",
        cafeteria: "Bengaluru Cafe",
        available: true,
      },
    ],
  });

  paymentService.setCustomFetch(async (url, opts) => {
    const payload = JSON.parse(opts.body);
    return {
      ok: true,
      status: 200,
      json: async () => ({
        cf_order_id: "cf_dosa_999",
        order_id: payload.order_id,
        order_amount: payload.order_amount,
        payment_session_id: "session_dosa_xyz",
      }),
    };
  });

  // Client checkout payload with menuItemId: null, name: "Masala Dosa", price: 60
  const result = await paymentService.createPaymentOrder(
    "student-123",
    "Extra crispy",
    "Bengaluru Cafe",
    [
      {
        menuItemId: null,
        name: "Masala Dosa",
        price: 60,
        quantity: 1,
      },
    ]
  );

  assert.equal(result.paymentGateway, "CASHFREE");
  assert.equal(result.amount, 63); // 1 * 60 + 3 GST = 63
  assert.equal(result.paymentSessionId, "session_dosa_xyz");
  assert.equal(userCart.items.length, 1);
  assert.equal(userCart.items[0].name, "Masala Dosa");
  assert.equal(userCart.items[0].quantity, 1);
});

