const ORDER_STATUS = {
    PENDING: "PENDING",
    CONFIRMED: "CONFIRMED",
    PREPARING: "PREPARING",
    READY: "READY",
    COMPLETED: "COMPLETED",
    CANCELLED: "CANCELLED",
  };
  
  const VALID_TRANSITIONS = {
    PENDING: ["CONFIRMED", "CANCELLED"],
    CONFIRMED: ["PREPARING", "CANCELLED"],
    PREPARING: ["READY"],
    READY: ["COMPLETED"],
    COMPLETED: [],
    CANCELLED: [],
  };
  
  function canTransition(currentStatus, nextStatus) {
    if (!ORDER_STATUS[nextStatus]) {
      return false;
    }
  
    return VALID_TRANSITIONS[currentStatus]?.includes(nextStatus) || false;
  }
  
  function validateTransition(currentStatus, nextStatus) {
    if (!canTransition(currentStatus, nextStatus)) {
      const error = new Error(
        `Invalid order status transition: ${currentStatus} -> ${nextStatus}`
      );
  
      error.statusCode = 400;
      throw error;
    }
  
    return true;
  }
  
  module.exports = {
    ORDER_STATUS,
    VALID_TRANSITIONS,
    canTransition,
    validateTransition,
  };