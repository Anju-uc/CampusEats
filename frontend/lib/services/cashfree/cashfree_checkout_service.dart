import 'cashfree_checkout_interface.dart';
import 'cashfree_checkout_stub.dart'
    if (dart.library.js_interop) 'cashfree_checkout_web.dart'
    if (dart.library.io) 'cashfree_checkout_mobile.dart';

export 'cashfree_checkout_interface.dart';

class CashfreeCheckoutService {
  static final CashfreeCheckoutPlatform _platform =
      getCashfreeCheckoutPlatform();

  static Future<CashfreePaymentSuccess> openCheckout(
    CashfreeCheckoutOptions options,
  ) {
    return _platform.open(options);
  }
}
