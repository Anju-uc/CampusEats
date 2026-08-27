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

function validateOrderId(orderId) {
  if (!ObjectId.isValid(orderId)) {
    const error = new Error("Invalid order ID");
    error.statusCode = 400;
    throw error;
  }
}

async function createOrder(userId, notes = "") {
  const cart = await getCartsCollection().findOne({ userId });

  if (!cart || !cart.items || cart.items.length === 0) {
    const error = new Error("Cart is empty");
    error.statusCode = 400;
    throw error;
  }

  const orderItems = [];
  let total = 0;

  for (const cartItem of cart.items) {
    const menuItem = await getMenuCollection().findOne({
      _id: cartItem.menuItemId,
    });

    if (!menuItem) {
      const error = new Error(
        "One or more menu items no longer exist"
      );
      error.statusCode = 400;
      throw error;
    }

    if (!menuItem.available) {
      const error = new Error(
        `Menu item "${menuItem.name}" is currently unavailable`
      );
      error.statusCode = 400;
      throw error;
    }

    const subtotal = menuItem.price * cartItem.quantity;

    orderItems.push({
      menuItemId: menuItem._id,
      name: menuItem.name,
      price: menuItem.price,
      quantity: cartItem.quantity,
      subtotal,
    });

    total += subtotal;
  }

  const now = new Date();

  const order = {
    userId,
    items: orderItems,
    total,
    status: ORDER_STATUS.PENDING,
    notes: notes || "",
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

  const updatedOrder = await getOrdersCollection().findOneAndUpdate(
    {
      _id: new ObjectId(orderId),
    },
    {
      $set: {
        status: nextStatus,
        updatedAt: new Date(),
      },
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
  getOrderById,
  updateOrderStatus,
  cancelOrder,
};