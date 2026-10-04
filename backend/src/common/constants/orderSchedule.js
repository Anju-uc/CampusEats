const SCHEDULED_PICKUP_WINDOW_MINUTES = 15;
const DEFAULT_PREPARATION_MINUTES = 15;
const MINIMUM_SCHEDULING_LEAD_MINUTES = 20;

const ORDER_TYPE = {
  ASAP: "ASAP",
  SCHEDULED: "SCHEDULED",
};

const PICKUP_STATUS = {
  NOT_SCHEDULED: "NOT_SCHEDULED",
  UPCOMING: "UPCOMING",
  READY: "READY",
  COLLECTED: "COLLECTED",
  NO_SHOW: "NO_SHOW",
  RELEASED: "RELEASED",
};

/**
 * Validates and calculates schedule parameters for an order.
 * Uses authoritative server time.
 *
 * @param {Object} options
 * @param {string} [options.orderType] - "ASAP" or "SCHEDULED"
 * @param {string|Date} [options.scheduledPickupAt] - ISO datetime string or Date object
 * @param {number} [options.estimatedPreparationMinutes] - optional custom preparation minutes
 * @param {Date} [options.serverNow] - optional reference time (defaults to new Date())
 * @returns {Object} Calculated schedule fields
 */
function validateAndCalculateSchedule({
  orderType = ORDER_TYPE.ASAP,
  scheduledPickupAt = null,
  estimatedPreparationMinutes = DEFAULT_PREPARATION_MINUTES,
  serverNow = new Date(),
} = {}) {
  const normalizedType =
    typeof orderType === "string" &&
    orderType.trim().toUpperCase() === ORDER_TYPE.SCHEDULED
      ? ORDER_TYPE.SCHEDULED
      : ORDER_TYPE.ASAP;

  if (normalizedType === ORDER_TYPE.ASAP && !scheduledPickupAt) {
    return {
      orderType: ORDER_TYPE.ASAP,
      scheduledPickupAt: null,
      pickupWindowEndAt: null,
      preparationStartAt: null,
      noShowAt: null,
      pickupStatus: PICKUP_STATUS.NOT_SCHEDULED,
    };
  }

  // SCHEDULED order validation
  if (!scheduledPickupAt) {
    const error = new Error("scheduledPickupAt is required for scheduled orders");
    error.statusCode = 400;
    throw error;
  }

  const pickupDate = new Date(scheduledPickupAt);
  if (isNaN(pickupDate.getTime())) {
    const error = new Error("Invalid datetime format for scheduledPickupAt");
    error.statusCode = 400;
    throw error;
  }

  const nowTime = serverNow.getTime();
  const pickupTime = pickupDate.getTime();

  if (pickupTime <= nowTime) {
    const error = new Error("Scheduled pickup time must be in the future");
    error.statusCode = 400;
    throw error;
  }

  // Maximum 7 days in advance
  const maxFutureTime = nowTime + 7 * 24 * 60 * 60 * 1000;
  if (pickupTime > maxFutureTime) {
    const error = new Error("Scheduled pickup time cannot be more than 7 days in advance");
    error.statusCode = 400;
    throw error;
  }

  const prepMinutes =
    Number.isInteger(estimatedPreparationMinutes) && estimatedPreparationMinutes > 0
      ? estimatedPreparationMinutes
      : DEFAULT_PREPARATION_MINUTES;

  const minLeadMinutes = Math.max(MINIMUM_SCHEDULING_LEAD_MINUTES, prepMinutes);
  if (pickupTime < nowTime + minLeadMinutes * 60 * 1000) {
    const error = new Error(
      `Scheduled pickup time must satisfy minimum preparation lead time (at least ${minLeadMinutes} minutes in advance)`
    );
    error.statusCode = 400;
    throw error;
  }

  const pickupWindowEndAt = new Date(
    pickupTime + SCHEDULED_PICKUP_WINDOW_MINUTES * 60 * 1000
  );
  const preparationStartAt = new Date(
    pickupTime - prepMinutes * 60 * 1000
  );

  return {
    orderType: ORDER_TYPE.SCHEDULED,
    scheduledPickupAt: pickupDate,
    pickupWindowEndAt,
    preparationStartAt,
    noShowAt: null,
    pickupStatus: PICKUP_STATUS.UPCOMING,
  };
}

module.exports = {
  SCHEDULED_PICKUP_WINDOW_MINUTES,
  DEFAULT_PREPARATION_MINUTES,
  MINIMUM_SCHEDULING_LEAD_MINUTES,
  ORDER_TYPE,
  PICKUP_STATUS,
  validateAndCalculateSchedule,
};
