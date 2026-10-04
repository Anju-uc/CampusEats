import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'cashfree_checkout_interface.dart';

CashfreeCheckoutPlatform getCashfreeCheckoutPlatform() => CashfreeCheckoutWeb();

class CashfreeCheckoutWeb implements CashfreeCheckoutPlatform {
  @override
  Future<CashfreePaymentSuccess> open(CashfreeCheckoutOptions options) {
    final completer = Completer<CashfreePaymentSuccess>();

    // 1. Try helper window.openCashfreeCheckout first
    final openFn = globalContext.getProperty<JSFunction?>(
      'openCashfreeCheckout'.toJS,
    );

    if (openFn != null) {
      final envMode = options.environment.trim().toLowerCase();
      final jsOptions = JSObject();
      jsOptions.setProperty('orderId'.toJS, options.orderId.toJS);
      jsOptions.setProperty('paymentSessionId'.toJS, options.paymentSessionId.toJS);
      jsOptions.setProperty('environment'.toJS, envMode.toJS);
      jsOptions.setProperty('redirectTarget'.toJS, '_modal'.toJS);

      final onComplete = ((JSObject? res) {
        if (!completer.isCompleted) {
          completer.complete(
            CashfreePaymentSuccess(
              orderId: options.orderId,
              paymentSessionId: options.paymentSessionId,
            ),
          );
        }
      }).toJS;

      final onError = ((JSString? err) {
        final errMsg = err?.toDart ?? 'Cashfree checkout closed or failed';
        if (!completer.isCompleted) {
          completer.completeError(Exception(errMsg));
        }
      }).toJS;

      try {
        openFn.callAsFunction(globalContext, jsOptions, onComplete, onError);
        return completer.future;
      } catch (e) {
        debugPrint('openCashfreeCheckout helper error, falling back: $e');
      }
    }

    // 2. Fallback to direct window.Cashfree
    final cashfreeConstructor = globalContext.getProperty<JSFunction?>(
      'Cashfree'.toJS,
    );
    if (cashfreeConstructor == null) {
      completer.completeError(
        Exception(
          'Cashfree SDK script not found. Please verify internet connection.',
        ),
      );
      return completer.future;
    }

    try {
      final initOptions = JSObject();
      initOptions.setProperty('mode'.toJS, options.environment.toJS);

      JSObject cfInstance;
      try {
        cfInstance = cashfreeConstructor.callAsFunction(
          globalContext,
          initOptions,
        ) as JSObject;
      } catch (_) {
        cfInstance = cashfreeConstructor.callAsConstructor<JSObject>(
          initOptions,
        );
      }

      final checkoutMethod = cfInstance.getProperty<JSFunction?>(
        'checkout'.toJS,
      );
      if (checkoutMethod == null) {
        completer.completeError(
          Exception('Cashfree checkout method is not available on instance.'),
        );
        return completer.future;
      }

      final checkoutOptions = JSObject();
      checkoutOptions.setProperty(
        'paymentSessionId'.toJS,
        options.paymentSessionId.toJS,
      );
      checkoutOptions.setProperty('redirectTarget'.toJS, '_modal'.toJS);

      final resultPromise = checkoutMethod.callAsFunction(
        cfInstance,
        checkoutOptions,
      ) as JSPromise?;

      if (resultPromise != null) {
        resultPromise.toDart.then(
          (resultObj) {
            final jsResult = resultObj as JSObject?;
            if (jsResult != null) {
              final errorObj = jsResult.getProperty<JSObject?>('error'.toJS);
              if (errorObj != null) {
                final message =
                    errorObj.getProperty<JSString?>('message'.toJS)?.toDart ??
                    'Payment was cancelled or failed.';
                if (!completer.isCompleted) {
                  completer.completeError(Exception(message));
                }
                return;
              }
            }

            if (!completer.isCompleted) {
              completer.complete(
                CashfreePaymentSuccess(
                  orderId: options.orderId,
                  paymentSessionId: options.paymentSessionId,
                ),
              );
            }
          },
          onError: (err) {
            if (!completer.isCompleted) {
              completer.completeError(
                Exception('Cashfree checkout modal closed or failed: $err'),
              );
            }
          },
        );
      } else {
        if (!completer.isCompleted) {
          completer.complete(
            CashfreePaymentSuccess(
              orderId: options.orderId,
              paymentSessionId: options.paymentSessionId,
            ),
          );
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Failed to launch Cashfree Web: $e'));
      }
    }

    return completer.future;
  }
}
