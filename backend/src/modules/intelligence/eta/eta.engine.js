function calculateEta({
    status,
    itemCount = 1,
    preparationMinutes = 10,
  }) {
    const statusExtraMinutes = {
      PENDING: 15,
      CONFIRMED: 12,
      PREPARING: 8,
      READY: 2,
      COMPLETED: 0,
      CANCELLED: 0,
    };
  
    const extra = statusExtraMinutes[status] ?? 15;
  
    const itemAdjustment = Math.max(0, itemCount - 1) * 2;
  
    const etaMinutes =
      status === "COMPLETED" || status === "CANCELLED"
        ? 0
        : Math.max(
            1,
            preparationMinutes + extra + itemAdjustment
          );
  
    return {
      etaMinutes,
      estimatedReadyAt:
        etaMinutes > 0
          ? new Date(Date.now() + etaMinutes * 60 * 1000)
          : null,
    };
  }
  
  module.exports = {
    calculateEta,
  };