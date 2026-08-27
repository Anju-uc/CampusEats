const EventEmitter = require("events");

const kitchenEvents = new EventEmitter();

function emitKitchenUpdate(order) {
  kitchenEvents.emit("kitchenOrderUpdated", {
    orderId: order._id.toString(),
    status: order.status,
    userId: order.userId,
    updatedAt: new Date(),
  });
}

function onKitchenUpdate(listener) {
  kitchenEvents.on("kitchenOrderUpdated", listener);

  return () => {
    kitchenEvents.off("kitchenOrderUpdated", listener);
  };
}

module.exports = {
  emitKitchenUpdate,
  onKitchenUpdate,
};