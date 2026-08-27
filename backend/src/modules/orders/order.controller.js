const orderService = require("./order.service");
const { getOrderEta } = require("../intelligence/eta/eta.service");

async function createOrder(req, res, next) {
  try {
    const order = await orderService.createOrder(
      req.user.uid,
      req.body.notes
    );

    res.status(201).json({
      status: "success",
      message: "Order created successfully",
      data: order,
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

module.exports = {
  createOrder,
  getMyOrders,
  getOrderById,
  getEta,
  updateOrderStatus,
  cancelOrder,
};