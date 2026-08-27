const EventEmitter = require("events");

const orderEvents = new EventEmitter();

function emitOrderStatusUpdate(orderId, status, extra = {}) {
  orderEvents.emit("orderStatusUpdated", {
    orderId,
    status,
    ...extra,
    updatedAt: new Date(),
  });
}

function onOrderStatusUpdate(listener) {
  orderEvents.on("orderStatusUpdated", listener);

  return () => {
    orderEvents.off("orderStatusUpdated", listener);
  };
}

function removeAllOrderListeners() {
  orderEvents.removeAllListeners("orderStatusUpdated");
}

module.exports = {
  emitOrderStatusUpdate,
  onOrderStatusUpdate,
  removeAllOrderListeners,
};