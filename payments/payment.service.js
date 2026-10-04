const crypto = require("node:crypto");
const path = require("node:path");
const { createRequire } = require("node:module");

const backendRequire = createRequire(
  path.resolve(__dirname, "../backend/package.json")
);
const { ObjectId } = backendRequire("mongodb");
const Razorpay = backendRequire("razorpay");
const { getDb } = require("../backend/src/config/mongodb");
const config = require("../backend/src/config/env");
const { ROLES } = require("../backend/src/common/constants/roles");
const { ORDER_STATUS } = require("../backend/src/common/constants/orderStatus");
const {
  PAYMENT_STATUS,
  PAYMENT_GATEWAY,
} = require("../backend/src/common/constants/paymentStatus");
const {
  emitOrderStatusUpdate,
} = require("../backend/src/realtime/orderRealtime.service");
const {
  emitKitchenUpdate,
} = require("../backend/src/realtime/kitchenRealtime.service");
const {
  validateAndCalculateSchedule,
  ORDER_TYPE,
  PICKUP_STATUS,
} = require("../backend/src/common/constants/orderSchedule");

const PAYMENTS_COLLECTION = "payments";
const ORDERS_COLLECTION = "orders";
const CARTS_COLLECTION = "carts";
const MENU_COLLECTION = "menu";
const USERS_COLLECTION = "users";

let razorpayClientInstance = null;
let customFetchInstance = null;

function getPaymentsCollection() {
  return getDb().collection(PAYMENTS_COLLECTION);
}

function getOrdersCollection() {
  return getDb().collection(ORDERS_COLLECTION);
}

function getCartsCollection() {
  return getDb().collection(CARTS_COLLECTION);
}

function getMenuCollection() {
  return getDb().collection(MENU_COLLECTION);
}

function getUsersCollection() {
  return getDb().collection(USERS_COLLECTION);
}

function getRazorpayClient() {
  if (razorpayClientInstance) {
    return razorpayClientInstance;
  }

  const keyId = config.razorpay?.keyId || process.env.RAZORPAY_KEY_ID;
  const keySecret =
    config.razorpay?.keySecret || process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret) {
    const error = new Error("Razorpay credentials are not configured on server");
    error.statusCode = 500;
    throw error;
  }

  razorpayClientInstance = new Razorpay({
    key_id: keyId,
    key_secret: keySecret,
  });

  return razorpayClientInstance;
}

function setRazorpayClient(client) {
  razorpayClientInstance = client;
}

function setCustomFetch(fn) {
  customFetchInstance = fn;
}

function getFetch() {
  return customFetchInstance || globalThis.fetch;
}

function getCashfreeBaseUrl() {
  const env = config.cashfree?.environment || process.env.CASHFREE_ENV || "sandbox";
  if (env === "production" || env === "prod" || env === "PROD") {
    return "https://api.cashfree.com/pg";
  }
  return "https://sandbox.cashfree.com/pg";
}

async function ensureIndexes() {
  const collection = getPaymentsCollection();
  await collection.createIndex({ cashfreeOrderId: 1 }, { sparse: true });
  await collection.createIndex({ razorpayOrderId: 1 }, { sparse: true });
  await collection.createIndex({ userId: 1 });
  await collection.createIndex({ status: 1 });
  await collection.createIndex({ createdAt: -1 });
  await collection.createIndex({ campusEatsOrderId: 1 });
}

async function ensureActiveCustomer(userId) {
  const user = await getUsersCollection().findOne({ uid: userId });

  if (
    !user ||
    (user.role !== ROLES.STUDENT && user.role !== ROLES.FACULTY) ||
    user.status !== "ACTIVE"
  ) {
    const error = new Error("An active student or faculty account is required");
    error.statusCode = 403;
    throw error;
  }

  return user;
}

const ensureActiveStudent = ensureActiveCustomer;

function escapeRegex(string) {
  return String(string).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function calculateCartTotal(userId, cafeteria = "", directItems = null) {
  let cart = null;
  if (!directItems || !Array.isArray(directItems) || directItems.length === 0) {
    cart = await getCartsCollection().findOne({ userId });
  }

  const sourceItems =
    cart?.items && Array.isArray(cart.items) && cart.items.length > 0
      ? cart.items
      : Array.isArray(directItems) && directItems.length > 0
      ? directItems
      : [];

  if (!sourceItems || sourceItems.length === 0) {
    const error = new Error("Cart is empty");
    error.statusCode = 400;
    throw error;
  }

  const orderItems = [];
  let total = 0;

  for (const cartItem of sourceItems) {
    let menuItem = null;
    const rawId = cartItem.menuItemId || cartItem.backendMenuItemId || cartItem.id || cartItem._id;

    if (rawId && ObjectId.isValid(String(rawId))) {
      menuItem = await getMenuCollection().findOne({
        _id: new ObjectId(String(rawId)),
      });
    }

    if (!menuItem && rawId) {
      menuItem = await getMenuCollection().findOne({
        $or: [
          { id: String(rawId) },
          { menuItemId: String(rawId) },
          { itemId: String(rawId) },
        ],
      });
    }

    if (!menuItem && cartItem.name) {
      const escaped = escapeRegex(String(cartItem.name).trim());
      menuItem = await getMenuCollection().findOne({
        name: { $regex: new RegExp(`^${escaped}$`, "i") },
      });
    }

    const quantity = Number(cartItem.quantity);

    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      const error = new Error("Order item quantity is invalid");
      error.statusCode = 400;
      throw error;
    }

    if (menuItem) {
      if (menuItem.available === false) {
        const error = new Error(
          `Menu item "${menuItem.name}" is currently unavailable`
        );
        error.statusCode = 400;
        throw error;
      }

      const itemPrice = Number(menuItem.price);
      const subtotal = itemPrice * quantity;

      orderItems.push({
        menuItemId: menuItem._id,
        name: menuItem.name,
        price: itemPrice,
        quantity,
        subtotal,
        cafeteria: menuItem.cafeteria || cartItem.cafeteria || cafeteria || "Bengaluru Cafe",
      });

      total += subtotal;
    } else if (cartItem.name && (Number(cartItem.price) > 0 || cartItem.price === 0)) {
      const itemPrice = Number(cartItem.price);
      const subtotal = itemPrice * quantity;

      orderItems.push({
        menuItemId: rawId ? String(rawId) : `item_${cartItem.name}`,
        name: cartItem.name,
        price: itemPrice,
        quantity,
        subtotal,
        cafeteria: cartItem.cafeteria || cafeteria || "Bengaluru Cafe",
      });

      total += subtotal;
    } else {
      const error = new Error("One or more menu items no longer exist");
      error.statusCode = 400;
      throw error;
    }
  }

  const GST_FLAT_AMOUNT = 3;
  const PICKUP_FEE = 0;
  const subtotal = total;
  const finalTotal = subtotal + GST_FLAT_AMOUNT + PICKUP_FEE;
  const amountPaise = Math.round(finalTotal * 100);

  if (amountPaise < 100) {
    const error = new Error("Order amount must be at least ₹1.00");
    error.statusCode = 400;
    throw error;
  }

  return {
    orderItems,
    subtotal,
    itemsTotal: subtotal,
    gst: GST_FLAT_AMOUNT,
    pickupFee: PICKUP_FEE,
    total: finalTotal,
    totalAmount: finalTotal,
    amountPaise,
  };
}

/**
 * Creates a Cashfree or Razorpay payment order based on server configuration.
 * Cashfree Sandbox is the primary active payment gateway.
 */
async function createPaymentOrder(
  userId,
  notes = "",
  cafeteria = "",
  items = null,
  scheduleOptions = {}
) {
  const user = await ensureActiveStudent(userId);

  const schedule = validateAndCalculateSchedule(scheduleOptions);

  if (Array.isArray(items) && items.length > 0) {
    try {
      const cartService = require("../backend/src/modules/cart/cart.service");
      await cartService.syncCart(userId, items);
    } catch (_) {
      // If syncCart fails, continue to authoritative calculateCartTotal
    }
  }

  const calculation = await calculateCartTotal(
    userId,
    cafeteria,
    items
  );
  const {
    orderItems,
    subtotal,
    itemsTotal,
    gst,
    pickupFee,
    total,
    amountPaise,
  } = calculation;

  const cashfreeClientId =
    config.cashfree?.clientId ||
    process.env.CASHFREE_CLIENT_ID ||
    process.env.CASHFREE_APP_ID;
  const cashfreeClientSecret =
    config.cashfree?.clientSecret ||
    process.env.CASHFREE_CLIENT_SECRET ||
    process.env.CASHFREE_SECRET_KEY;

  // 1. CASHFREE SANDBOX PAYMENT GATEWAY (PRIMARY)
  if (cashfreeClientId && cashfreeClientSecret) {
    const orderId = `order_${Date.now()}_${crypto.randomBytes(4).toString("hex")}`;
    const baseUrl = getCashfreeBaseUrl();
    const apiVersion =
      config.cashfree?.apiVersion ||
      process.env.CASHFREE_API_VERSION ||
      "2025-01-01";
    const environment =
      config.cashfree?.environment ||
      process.env.CASHFREE_ENV ||
      "sandbox";

    const cleanCustomerId = String(userId).replace(/[^a-zA-Z0-9_-]/g, "_").substring(0, 50);
    const userRoleStr = (user.role || (user.staffId ? "Faculty" : "Student")).toLowerCase();
    const cleanEmail = (user.email && !user.email.endsWith(".internal") && !user.email.endsWith(".local"))
      ? user.email
      : `${userRoleStr === "faculty" ? "faculty" : "student"}@campuseats.com`;

    const cashfreePayload = {
      order_id: orderId,
      order_amount: Number(total.toFixed(2)),
      order_currency: "INR",
      customer_details: {
        customer_id: cleanCustomerId || "cust_user",
        customer_name:
          user.name ||
          user.displayName ||
          user.staffId ||
          user.rollNumber ||
          user.studentId ||
          (user.role === ROLES.FACULTY ? "Faculty" : "Student"),
        customer_email: cleanEmail,
        customer_phone: "9876543210",
      },
      order_meta: {
        return_url: "https://merchants.cashfree.com/simulate?order_id={order_id}",
      },
      order_note: notes || `CampusEATS Order - ${cafeteria || orderItems[0]?.cafeteria || "Bengaluru Cafe"}`,
    };

    const fetchFn = getFetch();
    let response;
    let data;

    try {
      response = await fetchFn(`${baseUrl}/orders`, {
        method: "POST",
        headers: {
          "x-client-id": cashfreeClientId,
          "x-client-secret": cashfreeClientSecret,
          "x-api-version": apiVersion,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(cashfreePayload),
      });
      data = await response.json();
    } catch (fetchErr) {
      const error = new Error(`Cashfree order creation network error: ${fetchErr.message}`);
      error.statusCode = 502;
      throw error;
    }

    if (!response.ok || !data?.payment_session_id) {
      const errMsg = data?.message || data?.error || "Failed to create Cashfree order";
      const error = new Error(`Cashfree gateway error: ${errMsg}`);
      error.statusCode = response.status || 500;
      throw error;
    }

    const now = new Date();
    const paymentRecord = {
      userId,
      gateway: PAYMENT_GATEWAY.CASHFREE,
      cashfreeOrderId: orderId,
      paymentSessionId: data.payment_session_id,
      cfOrderId: data.cf_order_id,
      subtotal,
      itemsTotal,
      gst,
      pickupFee,
      totalAmount: total,
      amount: total,
      amountPaise,
      currency: "INR",
      status: PAYMENT_STATUS.CREATED,
      campusEatsOrderId: null,
      notes: notes || "",
      itemsSnapshot: orderItems,
      cafeteria: cafeteria || orderItems[0]?.cafeteria || "Bengaluru Cafe",
      orderType: schedule.orderType,
      scheduledPickupAt: schedule.scheduledPickupAt,
      pickupWindowEndAt: schedule.pickupWindowEndAt,
      preparationStartAt: schedule.preparationStartAt,
      noShowAt: null,
      pickupStatus: schedule.pickupStatus,
      createdAt: now,
      updatedAt: now,
    };

    await getPaymentsCollection().insertOne(paymentRecord);

    return {
      paymentGateway: PAYMENT_GATEWAY.CASHFREE,
      paymentSessionId: data.payment_session_id,
      cashfreeOrderId: orderId,
      orderId,
      subtotal,
      gst,
      pickupFee,
      totalAmount: total,
      amount: total,
      amountPaise,
      currency: "INR",
      environment,
      orderType: schedule.orderType,
      scheduledPickupAt: schedule.scheduledPickupAt,
      pickupWindowEndAt: schedule.pickupWindowEndAt,
      preparationStartAt: schedule.preparationStartAt,
      pickupStatus: schedule.pickupStatus,
    };
  }

  // 2. RAZORPAY FALLBACK (ISOLATED)
  const razorpayKeyId = config.razorpay?.keyId || process.env.RAZORPAY_KEY_ID;
  const razorpayKeySecret =
    config.razorpay?.keySecret || process.env.RAZORPAY_KEY_SECRET;

  if (razorpayKeyId && razorpayKeySecret) {
    const client = getRazorpayClient();
    const receiptId = `rcpt_${Date.now()}_${String(userId).slice(-6)}`;

    const razorpayOrder = await client.orders.create({
      amount: amountPaise,
      currency: "INR",
      receipt: receiptId,
      notes: {
        userId,
        cafeteria: cafeteria || orderItems[0]?.cafeteria || "Bengaluru Cafe",
      },
    });

    const now = new Date();
    const paymentRecord = {
      userId,
      gateway: PAYMENT_GATEWAY.RAZORPAY,
      razorpayOrderId: razorpayOrder.id,
      subtotal,
      itemsTotal,
      gst,
      pickupFee,
      totalAmount: total,
      amount: total,
      amountPaise,
      currency: "INR",
      status: PAYMENT_STATUS.CREATED,
      campusEatsOrderId: null,
      razorpayPaymentId: null,
      razorpaySignature: null,
      notes: notes || "",
      itemsSnapshot: orderItems,
      cafeteria: cafeteria || orderItems[0]?.cafeteria || "Bengaluru Cafe",
      orderType: schedule.orderType,
      scheduledPickupAt: schedule.scheduledPickupAt,
      pickupWindowEndAt: schedule.pickupWindowEndAt,
      preparationStartAt: schedule.preparationStartAt,
      noShowAt: null,
      pickupStatus: schedule.pickupStatus,
      createdAt: now,
      updatedAt: now,
    };

    await getPaymentsCollection().insertOne(paymentRecord);

    return {
      paymentGateway: PAYMENT_GATEWAY.RAZORPAY,
      razorpayOrderId: razorpayOrder.id,
      orderId: razorpayOrder.id,
      amount: amountPaise,
      currency: "INR",
      keyId: razorpayKeyId,
      orderType: schedule.orderType,
      scheduledPickupAt: schedule.scheduledPickupAt,
      pickupWindowEndAt: schedule.pickupWindowEndAt,
      preparationStartAt: schedule.preparationStartAt,
      pickupStatus: schedule.pickupStatus,
    };
  }

  const error = new Error("Payment gateway credentials are not configured on server");
  error.statusCode = 500;
  throw error;
}

/**
 * Verifies payment with Cashfree Sandbox or Razorpay and creates the authoritative CampusEATS order.
 */
async function verifyPayment(userId, payload) {
  const user = await ensureActiveCustomer(userId);

  const {
    cashfreeOrderId,
    orderId,
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
  } = payload || {};

  const targetCashfreeId = cashfreeOrderId || orderId;

  // ------------------------------------------------------------
  // A. CASHFREE PAYMENT VERIFICATION
  // ------------------------------------------------------------
  if (targetCashfreeId && (!razorpaySignature || !razorpayPaymentId)) {
    const paymentRecord = await getPaymentsCollection().findOne({
      cashfreeOrderId: targetCashfreeId,
    });

    if (!paymentRecord) {
      const error = new Error("Payment intent record not found");
      error.statusCode = 404;
      throw error;
    }

    if (paymentRecord.userId !== userId) {
      const error = new Error(
        "Payment order does not belong to the authenticated user"
      );
      error.statusCode = 403;
      throw error;
    }

    // Idempotency: return existing order if already captured
    if (
      paymentRecord.status === PAYMENT_STATUS.CAPTURED &&
      paymentRecord.campusEatsOrderId
    ) {
      const existingOrder = await getOrdersCollection().findOne({
        _id: paymentRecord.campusEatsOrderId,
      });

      if (existingOrder) {
        return {
          order: existingOrder,
          orderId: targetCashfreeId,
          isExisting: true,
        };
      }
    }

    // Call Cashfree API to verify payment status
    const cashfreeClientId =
      config.cashfree?.clientId ||
      process.env.CASHFREE_CLIENT_ID ||
      process.env.CASHFREE_APP_ID;
    const cashfreeClientSecret =
      config.cashfree?.clientSecret ||
      process.env.CASHFREE_CLIENT_SECRET ||
      process.env.CASHFREE_SECRET_KEY;
    const baseUrl = getCashfreeBaseUrl();
    const apiVersion =
      config.cashfree?.apiVersion ||
      process.env.CASHFREE_API_VERSION ||
      "2025-01-01";

    const fetchFn = getFetch();
    let cfOrderData;

    try {
      const response = await fetchFn(`${baseUrl}/orders/${targetCashfreeId}`, {
        method: "GET",
        headers: {
          "x-client-id": cashfreeClientId,
          "x-client-secret": cashfreeClientSecret,
          "x-api-version": apiVersion,
        },
      });
      cfOrderData = await response.json();
    } catch (fetchErr) {
      const error = new Error(`Cashfree order status check failed: ${fetchErr.message}`);
      error.statusCode = 502;
      throw error;
    }

    const orderStatus = cfOrderData?.order_status;

    if (orderStatus !== "PAID") {
      await getPaymentsCollection().updateOne(
        { _id: paymentRecord._id },
        {
          $set: {
            status: PAYMENT_STATUS.FAILED,
            error: `Cashfree order status: ${orderStatus || "UNKNOWN"}`,
            updatedAt: new Date(),
          },
        }
      );

      const error = new Error(
        orderStatus === "ACTIVE"
          ? "Payment has not been completed yet."
          : `Payment verification failed (Order status: ${orderStatus || "UNKNOWN"})`
      );
      error.statusCode = 400;
      throw error;
    }

    // Verify amount
    const paidAmount = Number(cfOrderData.order_amount);
    if (Math.abs(paidAmount - paymentRecord.amount) > 0.01) {
      const error = new Error("Payment amount mismatch with server record");
      error.statusCode = 400;
      throw error;
    }

    const now = new Date();
    const subtotal = paymentRecord.subtotal !== undefined
      ? paymentRecord.subtotal
      : (Array.isArray(paymentRecord.itemsSnapshot)
          ? paymentRecord.itemsSnapshot.reduce(
              (sum, item) => sum + (Number(item.subtotal) || (Number(item.price) * Number(item.quantity))),
              0
            )
          : paymentRecord.amount);
    const gst = paymentRecord.gst !== undefined ? paymentRecord.gst : 3;
    const pickupFee = paymentRecord.pickupFee !== undefined ? paymentRecord.pickupFee : 0;
    const totalAmount = paymentRecord.amount !== undefined ? paymentRecord.amount : (subtotal + gst + pickupFee);

    const orderDoc = {
      userId,
      userRole: user.role,
      userType: user.role === ROLES.FACULTY ? "Faculty" : "Student",
      customerType: user.role === ROLES.FACULTY ? "Faculty" : "Student",
      customerName:
        user.name ||
        user.displayName ||
        user.staffId ||
        user.rollNumber ||
        user.studentId ||
        (user.role === ROLES.FACULTY ? "Faculty" : "Student"),
      studentName:
        user.name ||
        user.displayName ||
        user.staffId ||
        user.rollNumber ||
        user.studentId ||
        (user.role === ROLES.FACULTY ? "Faculty" : "Student"),
      items: paymentRecord.itemsSnapshot,
      subtotal,
      itemsTotal: subtotal,
      gst,
      pickupFee,
      total: totalAmount,
      totalAmount,
      status: ORDER_STATUS.PENDING,
      paymentStatus: "Paid",
      paymentId: paymentRecord._id,
      paymentGateway: PAYMENT_GATEWAY.CASHFREE,
      cashfreeOrderId: targetCashfreeId,
      cfOrderId: cfOrderData.cf_order_id,
      notes: paymentRecord.notes || "",
      cafeteria: paymentRecord.cafeteria || "Bengaluru Cafe",
      orderType: paymentRecord.orderType || ORDER_TYPE.ASAP,
      scheduledPickupAt: paymentRecord.scheduledPickupAt || null,
      pickupWindowEndAt: paymentRecord.pickupWindowEndAt || null,
      preparationStartAt: paymentRecord.preparationStartAt || null,
      noShowAt: null,
      pickupStatus:
        paymentRecord.pickupStatus ||
        (paymentRecord.orderType === ORDER_TYPE.SCHEDULED
          ? PICKUP_STATUS.UPCOMING
          : PICKUP_STATUS.NOT_SCHEDULED),
      createdAt: now,
      updatedAt: now,
    };

    const insertResult = await getOrdersCollection().insertOne(orderDoc);
    const createdOrder = { ...orderDoc, _id: insertResult.insertedId };

    // Update payment record to CAPTURED
    await getPaymentsCollection().updateOne(
      { _id: paymentRecord._id },
      {
        $set: {
          status: PAYMENT_STATUS.CAPTURED,
          campusEatsOrderId: insertResult.insertedId,
          cfOrderId: cfOrderData.cf_order_id,
          updatedAt: now,
        },
      }
    );

    // Clear student's cart
    await getCartsCollection().updateOne(
      { userId },
      { $set: { items: [], updatedAt: now } }
    );

    // Realtime broadcast to student & kitchen
    emitOrderStatusUpdate(createdOrder);
    emitKitchenUpdate(createdOrder);

    return {
      order: createdOrder,
      orderId: targetCashfreeId,
      isExisting: false,
    };
  }

  // ------------------------------------------------------------
  // B. RAZORPAY PAYMENT VERIFICATION (LEGACY / ISOLATED)
  // ------------------------------------------------------------
  const targetRazorpayOrderId = razorpayOrderId || orderId;

  const paymentRecord = await getPaymentsCollection().findOne({
    razorpayOrderId: targetRazorpayOrderId,
  });

  if (!paymentRecord) {
    const error = new Error("Payment intent record not found");
    error.statusCode = 404;
    throw error;
  }

  if (paymentRecord.userId !== userId) {
    const error = new Error(
      "Payment order does not belong to the authenticated user"
    );
    error.statusCode = 403;
    throw error;
  }

  if (
    paymentRecord.status === PAYMENT_STATUS.CAPTURED &&
    paymentRecord.campusEatsOrderId
  ) {
    const existingOrder = await getOrdersCollection().findOne({
      _id: paymentRecord.campusEatsOrderId,
    });

    if (existingOrder) {
      return {
        order: existingOrder,
        paymentId: paymentRecord.razorpayPaymentId || razorpayPaymentId,
        isExisting: true,
      };
    }
  }

  const keySecret =
    config.razorpay?.keySecret || process.env.RAZORPAY_KEY_SECRET;

  if (!keySecret) {
    const error = new Error("Razorpay key secret is not configured on server");
    error.statusCode = 500;
    throw error;
  }

  const payloadString = `${targetRazorpayOrderId}|${razorpayPaymentId}`;
  const generatedSignature = crypto
    .createHmac("sha256", keySecret)
    .update(payloadString)
    .digest("hex");

  const isSignatureValid =
    Buffer.byteLength(generatedSignature) ===
      Buffer.byteLength(razorpaySignature || "") &&
    crypto.timingSafeEqual(
      Buffer.from(generatedSignature, "utf8"),
      Buffer.from(razorpaySignature || "", "utf8")
    );

  if (!isSignatureValid) {
    await getPaymentsCollection().updateOne(
      { _id: paymentRecord._id },
      {
        $set: {
          status: PAYMENT_STATUS.FAILED,
          razorpayPaymentId,
          error: "Invalid signature",
          updatedAt: new Date(),
        },
      }
    );

    const error = new Error("Invalid payment signature");
    error.statusCode = 400;
    throw error;
  }

  const client = getRazorpayClient();
  if (client.payments && typeof client.payments.fetch === "function") {
    try {
      const razorpayPayment = await client.payments.fetch(razorpayPaymentId);

      if (razorpayPayment.order_id !== targetRazorpayOrderId) {
        throw new Error("Payment order ID mismatch with Razorpay record");
      }

      if (Number(razorpayPayment.amount) !== Number(paymentRecord.amountPaise)) {
        throw new Error("Payment amount mismatch with server record");
      }

      if (
        razorpayPayment.currency &&
        razorpayPayment.currency.toUpperCase() !==
          paymentRecord.currency.toUpperCase()
      ) {
        throw new Error("Payment currency mismatch with server record");
      }
    } catch (err) {
      if (err.statusCode || err.message.includes("mismatch")) {
        await getPaymentsCollection().updateOne(
          { _id: paymentRecord._id },
          {
            $set: {
              status: PAYMENT_STATUS.FAILED,
              razorpayPaymentId,
              error: err.message,
              updatedAt: new Date(),
            },
          }
        );
        const error = new Error(`Payment verification failed: ${err.message}`);
        error.statusCode = 400;
        throw error;
      }
    }
  }

  const now = new Date();
  const subtotal = paymentRecord.subtotal !== undefined
    ? paymentRecord.subtotal
    : (Array.isArray(paymentRecord.itemsSnapshot)
        ? paymentRecord.itemsSnapshot.reduce(
            (sum, item) => sum + (Number(item.subtotal) || (Number(item.price) * Number(item.quantity))),
            0
          )
        : paymentRecord.amount);
  const gst = paymentRecord.gst !== undefined ? paymentRecord.gst : 3;
  const pickupFee = paymentRecord.pickupFee !== undefined ? paymentRecord.pickupFee : 0;
  const totalAmount = paymentRecord.amount !== undefined ? paymentRecord.amount : (subtotal + gst + pickupFee);

  const orderDoc = {
    userId,
    userRole: user.role,
    userType: user.role === ROLES.FACULTY ? "Faculty" : "Student",
    customerType: user.role === ROLES.FACULTY ? "Faculty" : "Student",
    customerName:
      user.name ||
      user.displayName ||
      user.staffId ||
      user.rollNumber ||
      user.studentId ||
      (user.role === ROLES.FACULTY ? "Faculty" : "Student"),
    studentName:
      user.name ||
      user.displayName ||
      user.staffId ||
      user.rollNumber ||
      user.studentId ||
      (user.role === ROLES.FACULTY ? "Faculty" : "Student"),
    items: paymentRecord.itemsSnapshot,
    subtotal,
    itemsTotal: subtotal,
    gst,
    pickupFee,
    total: totalAmount,
    totalAmount,
    status: ORDER_STATUS.PENDING,
    paymentStatus: "Paid",
    paymentId: paymentRecord._id,
    paymentGateway: PAYMENT_GATEWAY.RAZORPAY,
    razorpayPaymentId,
    razorpayOrderId: targetRazorpayOrderId,
    notes: paymentRecord.notes || "",
    cafeteria: paymentRecord.cafeteria || "Bengaluru Cafe",
    orderType: paymentRecord.orderType || ORDER_TYPE.ASAP,
    scheduledPickupAt: paymentRecord.scheduledPickupAt || null,
    pickupWindowEndAt: paymentRecord.pickupWindowEndAt || null,
    preparationStartAt: paymentRecord.preparationStartAt || null,
    noShowAt: null,
    pickupStatus:
      paymentRecord.pickupStatus ||
      (paymentRecord.orderType === ORDER_TYPE.SCHEDULED
        ? PICKUP_STATUS.UPCOMING
        : PICKUP_STATUS.NOT_SCHEDULED),
    createdAt: now,
    updatedAt: now,
  };

  const insertResult = await getOrdersCollection().insertOne(orderDoc);
  const createdOrder = { ...orderDoc, _id: insertResult.insertedId };

  await getPaymentsCollection().updateOne(
    { _id: paymentRecord._id },
    {
      $set: {
        status: PAYMENT_STATUS.CAPTURED,
        campusEatsOrderId: insertResult.insertedId,
        razorpayPaymentId,
        razorpaySignature,
        updatedAt: now,
      },
    }
  );

  await getCartsCollection().updateOne(
    { userId },
    { $set: { items: [], updatedAt: now } }
  );

  emitOrderStatusUpdate(createdOrder);
  emitKitchenUpdate(createdOrder);

  return {
    order: createdOrder,
    paymentId: razorpayPaymentId,
    isExisting: false,
  };
}

async function handleWebhook(rawBody, signature, headers = {}) {
  // Cashfree Webhook
  const cashfreeSecret =
    config.cashfree?.clientSecret || process.env.CASHFREE_CLIENT_SECRET;
  const cfSignature = headers["x-webhook-signature"];

  if (cfSignature && cashfreeSecret) {
    const timestamp = headers["x-webhook-timestamp"];
    const payload = `${timestamp}${rawBody}`;
    const expectedSignature = crypto
      .createHmac("sha256", cashfreeSecret)
      .update(payload)
      .digest("base64");

    if (cfSignature !== expectedSignature) {
      const error = new Error("Invalid Cashfree webhook signature");
      error.statusCode = 400;
      throw error;
    }

    const event = JSON.parse(rawBody.toString("utf8"));
    if (event.type === "PAYMENT_SUCCESS_WEBHOOK") {
      const orderId = event.data?.order?.order_id;
      const paymentRecord = await getPaymentsCollection().findOne({
        cashfreeOrderId: orderId,
      });

      if (paymentRecord && paymentRecord.status !== PAYMENT_STATUS.CAPTURED) {
        await verifyPayment(paymentRecord.userId, {
          cashfreeOrderId: orderId,
        });
      }
    }

    return { received: true };
  }

  // Razorpay Webhook
  const razorpaySecret =
    config.razorpay?.webhookSecret || process.env.RAZORPAY_WEBHOOK_SECRET;

  if (!razorpaySecret) {
    const error = new Error("Webhook secret is not configured on server");
    error.statusCode = 500;
    throw error;
  }

  if (!signature) {
    const error = new Error("Missing webhook signature");
    error.statusCode = 400;
    throw error;
  }

  const expectedSignature = crypto
    .createHmac("sha256", razorpaySecret)
    .update(rawBody)
    .digest("hex");

  const isValid =
    Buffer.byteLength(expectedSignature) === Buffer.byteLength(signature) &&
    crypto.timingSafeEqual(
      Buffer.from(expectedSignature, "utf8"),
      Buffer.from(signature, "utf8")
    );

  if (!isValid) {
    const error = new Error("Invalid webhook signature");
    error.statusCode = 400;
    throw error;
  }

  const event = JSON.parse(rawBody.toString("utf8"));
  if (event.event === "payment.captured") {
    const paymentEntity = event.payload?.payment?.entity;
    const razorpayOrderId = paymentEntity?.order_id;
    const razorpayPaymentId = paymentEntity?.id;

    if (razorpayOrderId && razorpayPaymentId) {
      const paymentRecord = await getPaymentsCollection().findOne({
        razorpayOrderId,
      });

      if (paymentRecord && paymentRecord.status !== PAYMENT_STATUS.CAPTURED) {
        await verifyPayment(paymentRecord.userId, {
          razorpayOrderId,
          razorpayPaymentId,
          razorpaySignature: "webhook_captured",
        }).catch(() => undefined);
        return { received: true, status: "captured" };
      }

      if (paymentRecord && paymentRecord.status === PAYMENT_STATUS.CAPTURED) {
        return { received: true, status: "already_captured" };
      }
    }
  }

  return { received: true };
}

module.exports = {
  createPaymentOrder,
  verifyPayment,
  handleWebhook,
  ensureIndexes,
  setRazorpayClient,
  setCustomFetch,
  getCashfreeBaseUrl,
};
