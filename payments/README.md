# CampusEATS Payment Module (Razorpay)

This module handles real-world Razorpay payment gateway integration for CampusEATS.

## Architecture

1. **Order Creation (`POST /api/payments/create-order`)**:
   - Authenticates active student and validates campus-access proof.
   - Authoritatively calculates the payable total from the user's cart in MongoDB Atlas `menu` collection.
   - Converts INR total to paise and creates a server-side Razorpay Order via official Razorpay SDK.
   - Records a payment intent in MongoDB `payments` collection.
   - Returns `{ razorpayOrderId, amount, currency, keyId }` to the client (Key Secret is never exposed).

2. **Payment Verification (`POST /api/payments/verify`)**:
   - Accepts `{ razorpayOrderId, razorpayPaymentId, razorpaySignature }`.
   - Computes HMAC SHA-256 signature using `RAZORPAY_KEY_SECRET` and performs constant-time comparison (`crypto.timingSafeEqual`).
   - Validates payment entity with Razorpay API (amount, currency, order_id).
   - Atomically inserts CampusEATS order into `orders` collection, updates `payments` record to `CAPTURED`, links `campusEatsOrderId`, and clears the user's cart in `carts` collection.
   - Prevents duplicate order creation if called repeatedly with the same payment.

3. **Webhook Processing (`POST /api/payments/webhook`)**:
   - Validates raw body signature against `RAZORPAY_WEBHOOK_SECRET`.
   - Idempotently reconciles `payment.captured` and `payment.failed` events.

## File Structure

- `payment.routes.js`: Express router for `/api/payments` endpoints.
- `payment.controller.js`: Request/response handler.
- `payment.service.js`: Razorpay business logic, database queries, and cryptographic signature validation.
- `payment.validator.js`: Input and header payload validation.
- `.gitkeep`: Directory persistence.
