const paymentController = require("./payment.controller");
const {
  authenticate: defaultAuthenticate,
} = require("../backend/src/middleware/auth.middleware");
const {
  requireCampusAccess: defaultRequireCampusAccess,
} = require("../backend/src/middleware/campusAccess.middleware");
const {
  validateCreateOrder,
  validateVerifyPayment,
  validateWebhook,
} = require("./payment.validator");

/**
 * Factory to create payment router using injected express/router instance.
 * Avoids direct express dependency resolution in root payments folder.
 *
 * @param {import('express').Router|import('express')} expressOrRouter
 * @param {Object} [options]
 * @returns {import('express').Router}
 */
function createPaymentRouter(expressOrRouter, options = {}) {
  if (!expressOrRouter) {
    throw new Error(
      "createPaymentRouter requires an express router or express instance"
    );
  }

  const router =
    typeof expressOrRouter.use === "function" &&
    typeof expressOrRouter.post === "function" &&
    !expressOrRouter.Router
      ? expressOrRouter
      : expressOrRouter.Router();

  const authenticate = options.authenticate || defaultAuthenticate;
  const requireCampusAccess =
    options.requireCampusAccess || defaultRequireCampusAccess;

  // Webhook endpoint (does not require student bearer auth, verified via signature)
  router.post(
    "/webhook",
    validateWebhook,
    paymentController.handleWebhook
  );

  // Protected endpoints for authenticated students
  router.post(
    "/create-order",
    authenticate,
    validateCreateOrder,
    paymentController.createPaymentOrder
  );

  router.post(
    "/verify",
    authenticate,
    validateVerifyPayment,
    paymentController.verifyPayment
  );

  return router;
}

module.exports = createPaymentRouter;
