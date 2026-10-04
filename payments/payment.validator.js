function validateCreateOrder(req, res, next) {
  const { notes, cafeteria, orderType, scheduledPickupAt } = req.body || {};

  if (notes !== undefined && typeof notes !== "string") {
    return res.status(400).json({
      status: "error",
      message: "notes must be a string",
    });
  }

  if (notes && notes.length > 500) {
    return res.status(400).json({
      status: "error",
      message: "notes must not exceed 500 characters",
    });
  }

  if (cafeteria !== undefined && typeof cafeteria !== "string") {
    return res.status(400).json({
      status: "error",
      message: "cafeteria must be a string",
    });
  }

  if (orderType !== undefined) {
    if (typeof orderType !== "string") {
      return res.status(400).json({
        status: "error",
        message: "orderType must be a string ('ASAP' or 'SCHEDULED')",
      });
    }
    const normalized = orderType.trim().toUpperCase();
    if (normalized !== "ASAP" && normalized !== "SCHEDULED") {
      return res.status(400).json({
        status: "error",
        message: "orderType must be either 'ASAP' or 'SCHEDULED'",
      });
    }
  }

  if (scheduledPickupAt !== undefined && scheduledPickupAt !== null) {
    const pickupDate = new Date(scheduledPickupAt);
    if (isNaN(pickupDate.getTime())) {
      return res.status(400).json({
        status: "error",
        message: "Invalid datetime format for scheduledPickupAt",
      });
    }
  }

  next();
}

function validateVerifyPayment(req, res, next) {
  const {
    cashfreeOrderId,
    orderId,
    razorpayOrderId,
    razorpayPaymentId,
    razorpaySignature,
  } = req.body || {};

  const targetCashfreeId = cashfreeOrderId || orderId;

  // Cashfree verification parameters
  if (targetCashfreeId && typeof targetCashfreeId === "string" && targetCashfreeId.trim()) {
    return next();
  }

  // Razorpay verification parameters (legacy)
  if (
    razorpayOrderId &&
    razorpayPaymentId &&
    razorpaySignature &&
    typeof razorpayOrderId === "string" &&
    typeof razorpayPaymentId === "string" &&
    typeof razorpaySignature === "string"
  ) {
    return next();
  }

  return res.status(400).json({
    status: "error",
    message: "Invalid payment verification parameters (orderId or payment details required)",
  });
}

function validateWebhook(req, res, next) {
  const razorpaySig = req.headers["x-razorpay-signature"];
  const cashfreeSig = req.headers["x-webhook-signature"];

  if (!razorpaySig && !cashfreeSig) {
    return res.status(400).json({
      status: "error",
      message: "Missing webhook signature header",
    });
  }

  if (!req.rawBody) {
    return res.status(400).json({
      status: "error",
      message: "Missing raw request body required for webhook verification",
    });
  }

  next();
}

module.exports = {
  validateCreateOrder,
  validateVerifyPayment,
  validateWebhook,
};
