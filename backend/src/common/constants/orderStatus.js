const ORDER_STATUS = Object.freeze({
    PENDING: "PENDING",
    CONFIRMED: "CONFIRMED",
    PREPARING: "PREPARING",
    READY: "READY",
    COMPLETED: "COMPLETED",
    CANCELLED: "CANCELLED",
  });
  
  const VALID_ORDER_STATUS = Object.freeze(
    Object.values(ORDER_STATUS)
  );
  
  module.exports = {
    ORDER_STATUS,
    VALID_ORDER_STATUS,
  };