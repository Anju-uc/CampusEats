const orderService = require("./order.service");
const { getOrderEta } = require("../intelligence/eta/eta.service");

async function createOrder(req, res, next) {
  try {
    return res.status(400).json({
      status: "error",
      code: "PAYMENT_REQUIRED",
      message:
        "Direct unpaid order creation is disabled. Please create a payment intent at /api/payments/create-order and complete verification at /api/payments/verify.",
    });
  } catch (error) {
    next(error);
  }
}

async function getMyOrders(req, res, next) {
  try {
    const orders = await orderService.getMyOrders(req.user.uid);

    res.status(200).json({
      status: "success",
      data: orders,
    });
  } catch (error) {
    next(error);
  }
}

async function getAllOrders(req, res, next) {
  try {
    const isStaff = req.user?.role === "Admin" || req.user?.role === "Kitchen";
    const cafeteria = isStaff
      ? req.user?.cafeteria
      : (req.query?.cafeteria || req.user?.cafeteria);
    const orders = await orderService.getAllOrders(cafeteria);

    res.status(200).json({
      status: "success",
      data: orders,
    });
  } catch (error) {
    next(error);
  }
}

async function getOrderById(req, res, next) {
  try {
    const order = await orderService.getOrderById(
      req.user.uid,
      req.params.id
    );

    res.status(200).json({
      status: "success",
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

async function getEta(req, res, next) {
  try {
    const eta = await getOrderEta(
      req.user.uid,
      req.params.id
    );

    res.status(200).json({
      status: "success",
      data: eta,
    });
  } catch (error) {
    next(error);
  }
}

async function updateOrderStatus(req, res, next) {
  try {
    const order = await orderService.updateOrderStatus(
      req.params.id,
      req.body.status
    );

    res.status(200).json({
      status: "success",
      message: "Order status updated successfully",
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

async function cancelOrder(req, res, next) {
  try {
    const order = await orderService.cancelOrder(
      req.user.uid,
      req.params.id
    );

    res.status(200).json({
      status: "success",
      message: "Order cancelled successfully",
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

async function markNoShow(req, res, next) {
  try {
    const order = await orderService.markNoShow(req.params.id);

    res.status(200).json({
      status: "success",
      message: "Order marked as NO_SHOW",
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

async function releaseUncollectedOrder(req, res, next) {
  try {
    const order = await orderService.releaseUncollectedOrder(req.params.id);

    res.status(200).json({
      status: "success",
      message: "Uncollected order released successfully",
      data: order,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createOrder,
  getMyOrders,
  getAllOrders,
  getOrderById,
  getEta,
  updateOrderStatus,
  markNoShow,
  releaseUncollectedOrder,
  cancelOrder,
};