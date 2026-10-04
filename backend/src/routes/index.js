const express = require("express");

const authRoutes = require("../modules/auth/auth.routes");
const userRoutes = require("../modules/users/user.routes");
const menuRoutes = require("../modules/menu/menu.routes");
const cartRoutes = require("../modules/cart/cart.routes");
const orderRoutes = require("../modules/orders/order.routes");
const reviewRoutes = require("../modules/reviews/review.routes");
const cafeteriaRoutes = require("../modules/reviews/cafeteria.routes");
const intelligenceRoutes = require("../modules/intelligence/intelligence.routes");
const kioskRoutes = require("../modules/kiosk/kiosk.routes");
const createPaymentRouter = require("../../../payments/payment.routes");

const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/menu", menuRoutes);
router.use("/cart", cartRoutes);
router.use("/orders", orderRoutes);
router.use("/payments", createPaymentRouter(express.Router()));
router.use("/reviews", reviewRoutes);
router.use("/cafeterias", cafeteriaRoutes);
router.use("/intelligence", intelligenceRoutes);
router.use("/kiosk", kioskRoutes);

module.exports = router;