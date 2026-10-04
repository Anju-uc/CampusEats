import 'razorpay_checkout_interface.dart';
import 'razorpay_checkout_stub.dart'
    if (dart.library.js_interop) 'razorpay_checkout_web.dart'
    if (dart.library.io) 'razorpay_checkout_mobile.dart';

export 'razorpay_checkout_interface.dart';

class RazorpayCheckoutService {
  static final RazorpayCheckoutPlatform _platform =
      getRazorpayCheckoutPlatform();

  static Future<RazorpayPaymentSuccess> openCheckout(
    RazorpayCheckoutOptions options,
  ) {
    return _platform.open(options);
  }
}
