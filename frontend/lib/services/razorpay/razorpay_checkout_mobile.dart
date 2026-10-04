import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_checkout_interface.dart';

RazorpayCheckoutPlatform getRazorpayCheckoutPlatform() =>
    RazorpayCheckoutMobile();

class RazorpayCheckoutMobile implements RazorpayCheckoutPlatform {
  @override
  Future<RazorpayPaymentSuccess> open(RazorpayCheckoutOptions options) {
    final completer = Completer<RazorpayPaymentSuccess>();
    final razorpay = Razorpay();

    void handleSuccess(PaymentSuccessResponse response) {
      razorpay.clear();
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayPaymentSuccess(
            razorpayOrderId: response.orderId ?? options.razorpayOrderId,
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          ),
        );
      }
    }

    void handleError(PaymentFailureResponse response) {
      razorpay.clear();
      if (!completer.isCompleted) {
        final message = response.message ?? 'Payment failed (${response.code})';
        completer.completeError(Exception(message));
      }
    }

    void handleExternalWallet(ExternalWalletResponse response) {
      razorpay.clear();
      if (!completer.isCompleted) {
        completer.completeError(
          Exception('External wallet selected: ${response.walletName}'),
        );
      }
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handleSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    final payload = {
      'key': options.keyId,
      'amount': options.amount,
      'name': options.name,
      'description': options.description,
      'order_id': options.razorpayOrderId,
      'currency': options.currency,
      'prefill': {
        'name': options.studentName,
        'email': options.studentEmail,
        'contact': options.contact,
      },
      'theme': {'color': '#FF9800'},
    };

    try {
      razorpay.open(payload);
    } catch (e) {
      razorpay.clear();
      completer.completeError(
        Exception('Failed to launch Razorpay checkout: $e'),
      );
    }

    return completer.future;
  }
}
