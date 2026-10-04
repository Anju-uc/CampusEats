const { ObjectId } = require("mongodb");
const { getDb } = require("../../config/mongodb");
const {
  ORDER_STATUS,
  validateTransition,
} = require("./orderStateMachine");

const {
  emitOrderStatusUpdate,
} = require("../../realtime/orderRealtime.service");

const {
  emitKitchenUpdate,
} = require("../../realtime/kitchenRealtime.service");
const { ROLES } = require("../../common/constants/roles");
const {
  validateAndCalculateSchedule,
  ORDER_TYPE,
  PICKUP_STATUS,
} = require("../../common/constants/orderSchedule");

const ORDERS_COLLECTION = "orders";
const CARTS_COLLECTION = "carts";
const MENU_COLLECTION = "menu";

function getOrdersCollection() {
  return getDb().collection(ORDERS_COLLECTION);
}

function getCartsCollection() {
  return getDb().collection(CARTS_COLLECTION);
}

function getMenuCollection() {
  return getDb().collection(MENU_COLLECTION);
}

async function ensureActiveCustomer(userId) {
  const user = await getDb().collection("users").findOne({ uid: userId });

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

function validateOrderId(orderId) {
  if (!ObjectId.isValid(orderId)) {
    const error = new Error("Invalid order ID");
    error.statusCode = 400;
    throw error;
  }
}

function escapeRegex(string) {
  return String(string).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

async function createOrder(
  userId,
  notes = "",
  requestedItems = [],
  scheduleOptions = {}
) {
  const user = await ensureActiveCustomer(userId);

  const schedule = validateAndCalculateSchedule(scheduleOptions);

  const cart = await getCartsCollection().findOne({ userId });

  const sourceItems = cart?.items?.length ? cart.items : requestedItems;

  if (!Array.isArray(sourceItems) || sourceItems.length === 0) {
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
      });

      total += subtotal;
    } else {
      const error = new Error(
        "One or more menu items no longer exist"
      );
      error.statusCode = 400;
      throw error;
    }
  }

  const GST_FLAT_AMOUNT = 3;
  const PICKUP_FEE = 0;
  const subtotal = total;
  const finalTotal = subtotal + GST_FLAT_AMOUNT + PICKUP_FEE;
  const now = new Date();

  const order = {
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
    items: orderItems,
    subtotal,
    itemsTotal: subtotal,
    gst: GST_FLAT_AMOUNT,
    pickupFee: PICKUP_FEE,
    total: finalTotal,
    totalAmount: finalTotal,
    status: ORDER_STATUS.PENDING,
    notes: notes || "",
    orderType: schedule.orderType,
    scheduledPickupAt: schedule.scheduledPickupAt,
    pickupWindowEndAt: schedule.pickupWindowEndAt,
    preparationStartAt: schedule.preparationStartAt,
    noShowAt: null,
    pickupStatus: schedule.pickupStatus,
    createdAt: now,
    updatedAt: now,
  };

  const result = await getOrdersCollection().insertOne(order);

  await getCartsCollection().updateOne(
    { userId },
    {
      $set: {
        items: [],
        updatedAt: now,
      },
    }
  );

  const createdOrder = {
    _id: result.insertedId,
    ...order,
  };

  emitOrderStatusUpdate(
    result.insertedId.toString(),
    ORDER_STATUS.PENDING
  );

  emitKitchenUpdate(createdOrder);

  return createdOrder;
}

async function getMyOrders(userId) {
  return getOrdersCollection()
    .find({ userId })
    .sort({ createdAt: -1 })
    .toArray();
}

async function getAllOrders(cafeteria = "") {
  const query = {};
  if (cafeteria && typeof cafeteria === "string" && cafeteria.trim()) {
    const trimmed = cafeteria.trim();
    query.$or = [
      { cafeteria: trimmed },
      { cafeteria: { $regex: new RegExp(`^${trimmed.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
      { "items.cafeteria": trimmed },
      { "items.cafeteria": { $regex: new RegExp(`^${trimmed.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "i") } },
    ];
  }
  return getOrdersCollection()
    .find(query)
    .sort({ createdAt: -1 })
    .toArray();
}

async function getOrderById(userId, orderId) {
  validateOrderId(orderId);

  const order = await getOrdersCollection().findOne({
    _id: new ObjectId(orderId),
    userId,
  });

  if (!order) {
    const error = new Error("Order not found");
    error.statusCode = 404;
    throw error;
  }

  return order;
}

async function updateOrderStatus(orderId, nextStatus) {
  validateOrderId(orderId);

  const order = await getOrdersCollection().findOne({
    _id: new ObjectId(orderId),
  });

  if (!order) {
    const error = new Error("Order not found");
    error.statusCode = 404;
    throw error;
  }

  validateTransition(order.status, nextStatus);

  const updateFields = {
    status: nextStatus,
    updatedAt: new Date(),
  };

  if (order.orderType === ORDER_TYPE.SCHEDULED) {
    if (nextStatus === ORDER_STATUS.READY) {
      updateFields.pickupStatus = PICKUP_STATUS.READY;
    } else if (nextStatus === ORDER_STATUS.COMPLETED) {
      updateFields.pickupStatus = PICKUP_STATUS.COLLECTED;
    }
  }

  const updatedOrder = await getOrdersCollection().findOneAndUpdate(
    {
      _id: new ObjectId(orderId),
      status: order.status,
    },
    {
      $set: updateFields,
    },
    {
      returnDocument: "after",
    }
  );

  if (!updatedOrder) {
    const error = new Error("Failed to update order status");
    error.statusCode = 500;
    throw error;
  }

  emitOrderStatusUpdate(
    orderId,
    nextStatus,
    {
      userId: order.userId,
      pickupStatus: updatedOrder.pickupStatus,
    }
  );

  emitKitchenUpdate(updatedOrder);

  return updatedOrder;
}

async function markNoShow(orderId) {
  validateOrderId(orderId);

  const order = await getOrdersCollection().findOne({
    _id: new ObjectId(orderId),
  });

  if (!order) {
    const error = new Error("Order not found");
    error.statusCode = 404;
    throw error;
  }

  if (order.orderType !== ORDER_TYPE.SCHEDULED) {
    const error = new Error("Only scheduled orders can be marked as NO_SHOW");
    error.statusCode = 400;
    throw error;
  }

  const now = new Date();
  if (
    !order.pickupWindowEndAt ||
    now.getTime() <= new Date(order.pickupWindowEndAt).getTime()
  ) {
    const error = new Error(
      "Cannot mark order as NO_SHOW before the 15-minute pickup window has expired"
    );
    error.statusCode = 400;
    throw error;
  }

  const updatedOrder = await getOrdersCollection().findOneAndUpdate(
    {
      _id: new ObjectId(orderId),
    },
    {
      $set: {
        pickupStatus: PICKUP_STATUS.NO_SHOW,
        noShowAt: now,
        updatedAt: now,
      },
    },
    {
      returnDocument: "after",
    }
  );

  emitOrderStatusUpdate(
    orderId,
    updatedOrder.status,
    {
      userId: order.userId,
      pickupStatus: PICKUP_STATUS.NO_SHOW,
    }
  );

  emitKitchenUpdate(updatedOrder);

  return updatedOrder;
}

async function releaseUncollectedOrder(orderId) {
  validateOrderId(orderId);

  const order = await getOrdersCollection().findOne({
    _id: new ObjectId(orderId),
  });

  if (!order) {
    const error = new Error("Order not found");
    error.statusCode = 404;
    throw error;
  }

  if (order.orderType !== ORDER_TYPE.SCHEDULED) {
    const error = new Error("Only scheduled orders can be released");
    error.statusCode = 400;
    throw error;
  }

  const now = new Date();
  const isExpired =
    order.pickupWindowEndAt &&
    now.getTime() > new Date(order.pickupWindowEndAt).getTime();

  if (order.pickupStatus !== PICKUP_STATUS.NO_SHOW && !isExpired) {
    const error = new Error(
      "Cannot release an order before the pickup window has expired or status is NO_SHOW"
    );
    error.statusCode = 400;
    throw error;
  }

  const updatedOrder = await getOrdersCollection().findOneAndUpdate(
    {
      _id: new ObjectId(orderId),
    },
    {
      $set: {
        pickupStatus: PICKUP_STATUS.RELEASED,
        releasedAt: now,
        noShowAt: order.noShowAt || now,
        updatedAt: now,
      },
    },
    {
      returnDocument: "after",
    }
  );

  emitOrderStatusUpdate(
    orderId,
    updatedOrder.status,
    {
      userId: order.userId,
      pickupStatus: PICKUP_STATUS.RELEASED,
    }
  );

  emitKitchenUpdate(updatedOrder);

  return updatedOrder;
}

async function cancelOrder(userId, orderId) {
  const order = await getOrderById(userId, orderId);

  validateTransition(
    order.status,
    ORDER_STATUS.CANCELLED
  );

  const updatedOrder = await getOrdersCollection().findOneAndUpdate(
    {
      _id: new ObjectId(orderId),
      userId,
    },
    {
      $set: {
        status: ORDER_STATUS.CANCELLED,
        updatedAt: new Date(),
      },
    },
    {
      returnDocument: "after",
    }
  );

  if (!updatedOrder) {
    const error = new Error("Failed to cancel order");
    error.statusCode = 500;
    throw error;
  }

  emitOrderStatusUpdate(
    orderId,
    ORDER_STATUS.CANCELLED,
    {
      userId,
    }
  );

  emitKitchenUpdate(updatedOrder);

  return updatedOrder;
}

module.exports = {
  createOrder,
  getMyOrders,
  getAllOrders,
  getOrderById,
  updateOrderStatus,
  markNoShow,
  releaseUncollectedOrder,
  cancelOrder,
};