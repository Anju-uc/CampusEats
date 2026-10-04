import 'dart:async';
import 'cashfree_checkout_interface.dart';

CashfreeCheckoutPlatform getCashfreeCheckoutPlatform() =>
    CashfreeCheckoutMobile();

class CashfreeCheckoutMobile implements CashfreeCheckoutPlatform {
  @override
  Future<CashfreePaymentSuccess> open(CashfreeCheckoutOptions options) {
    throw UnsupportedError(
      'Mobile native Cashfree checkout requires mobile SDK integration. For testing in browser, use Flutter Web.',
    );
  }
}
