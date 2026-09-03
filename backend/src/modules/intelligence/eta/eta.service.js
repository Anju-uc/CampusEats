const { ObjectId } = require("mongodb");
const { getDb } = require("../../../config/mongodb");
const { calculateEta } = require("./eta.engine");

async function getOrderEta(userId, orderId) {
  if (!ObjectId.isValid(orderId)) {
    const error = new Error("Invalid order ID");
    error.statusCode = 400;
    throw error;
  }

  const order = await getDb().collection("orders").findOne({
    _id: new ObjectId(orderId),
    userId,
  });

  if (!order) {
    const error = new Error("Order not found");
    error.statusCode = 404;
    throw error;
  }

  const itemCount = (order.items || []).reduce(
    (total, item) => total + item.quantity,
    0
  );

  return {
    orderId: order._id,
    status: order.status,
    ...calculateEta({
      status: order.status,
      itemCount,
    }),
  };
}

module.exports = {
  getOrderEta,
};