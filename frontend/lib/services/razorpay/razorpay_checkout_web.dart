import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'razorpay_checkout_interface.dart';

RazorpayCheckoutPlatform getRazorpayCheckoutPlatform() => RazorpayCheckoutWeb();

class RazorpayCheckoutWeb implements RazorpayCheckoutPlatform {
  @override
  Future<RazorpayPaymentSuccess> open(RazorpayCheckoutOptions options) {
    final completer = Completer<RazorpayPaymentSuccess>();

    // Construct JS options object
    final jsOptions = JSObject();
    jsOptions.setProperty('key'.toJS, options.keyId.toJS);
    jsOptions.setProperty('amount'.toJS, options.amount.toJS);
    jsOptions.setProperty('currency'.toJS, options.currency.toJS);
    jsOptions.setProperty('name'.toJS, options.name.toJS);
    jsOptions.setProperty('description'.toJS, options.description.toJS);
    jsOptions.setProperty('order_id'.toJS, options.razorpayOrderId.toJS);

    // Prefill
    final prefill = JSObject();
    prefill.setProperty('name'.toJS, options.studentName.toJS);
    prefill.setProperty('email'.toJS, options.studentEmail.toJS);
    prefill.setProperty('contact'.toJS, options.contact.toJS);
    jsOptions.setProperty('prefill'.toJS, prefill);

    // Theme
    final theme = JSObject();
    theme.setProperty('color'.toJS, '#FF9800'.toJS);
    jsOptions.setProperty('theme'.toJS, theme);

    // Handler callback on success
    final handler = ((JSObject response) {
      final paymentId =
          response.getProperty<JSString?>('razorpay_payment_id'.toJS)?.toDart ??
          '';
      final orderId =
          response.getProperty<JSString?>('razorpay_order_id'.toJS)?.toDart ??
          options.razorpayOrderId;
      final signature =
          response.getProperty<JSString?>('razorpay_signature'.toJS)?.toDart ??
          '';

      if (!completer.isCompleted) {
        completer.complete(
          RazorpayPaymentSuccess(
            razorpayOrderId: orderId.isNotEmpty
                ? orderId
                : options.razorpayOrderId,
            razorpayPaymentId: paymentId,
            razorpaySignature: signature,
          ),
        );
      }
    }).toJS;
    jsOptions.setProperty('handler'.toJS, handler);

    // Modal ondismiss
    final modal = JSObject();
    final onDismiss = (() {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Payment cancelled by user'));
      }
    }).toJS;
    modal.setProperty('ondismiss'.toJS, onDismiss);
    jsOptions.setProperty('modal'.toJS, modal);

    // Verify window.Razorpay constructor
    final razorpayConstructor = globalContext.getProperty<JSFunction?>(
      'Razorpay'.toJS,
    );
    if (razorpayConstructor == null) {
      completer.completeError(
        Exception(
          'Razorpay checkout script not found. Please verify internet connection.',
        ),
      );
      return completer.future;
    }

    try {
      final rzpInstance = razorpayConstructor.callAsConstructor<JSObject>(
        jsOptions,
      );

      // Listen for payment.failed
      final onMethod = rzpInstance.getProperty<JSFunction?>('on'.toJS);
      if (onMethod != null) {
        final failHandler = ((JSObject err) {
          final errorObj = err.getProperty<JSObject?>('error'.toJS);
          final desc =
              errorObj?.getProperty<JSString?>('description'.toJS)?.toDart ??
              'Payment failed';
          if (!completer.isCompleted) {
            completer.completeError(Exception(desc));
          }
        }).toJS;
        onMethod.callAsFunction(
          rzpInstance,
          'payment.failed'.toJS,
          failHandler,
        );
      }

      final openMethod = rzpInstance.getProperty<JSFunction?>('open'.toJS);
      if (openMethod != null) {
        openMethod.callAsFunction(rzpInstance);
      } else {
        completer.completeError(
          Exception('Failed to open Razorpay checkout dialog'),
        );
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to launch Razorpay Web: $e'));
      }
    }

    return completer.future;
  }
}
