const paymentService = require("./payment.service");

async function createPaymentOrder(req, res, next) {
  try {
    const result = await paymentService.createPaymentOrder(
      req.user.uid,
      req.body.notes,
      req.body.cafeteria,
      req.body.items,
      {
        orderType: req.body.orderType,
        scheduledPickupAt: req.body.scheduledPickupAt,
      }
    );

    res.status(201).json({
      status: "success",
      message: "Payment order created successfully",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const result = await paymentService.verifyPayment(
      req.user.uid,
      req.body
    );

    res.status(200).json({
      status: "success",
      message: "Payment verified and order created successfully",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

async function handleWebhook(req, res, next) {
  try {
    const signature = req.headers["x-razorpay-signature"];
    const result = await paymentService.handleWebhook(
      req.rawBody,
      signature
    );

    res.status(200).json({
      status: "success",
      data: result,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createPaymentOrder,
  verifyPayment,
  handleWebhook,
};
