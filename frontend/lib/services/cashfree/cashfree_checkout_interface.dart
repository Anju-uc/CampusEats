class CashfreeCheckoutOptions {
  final String paymentSessionId;
  final String orderId;
  final String environment; // 'sandbox' or 'production'

  const CashfreeCheckoutOptions({
    required this.paymentSessionId,
    required this.orderId,
    this.environment = 'sandbox',
  });
}

class CashfreePaymentSuccess {
  final String orderId;
  final String paymentSessionId;

  const CashfreePaymentSuccess({
    required this.orderId,
    required this.paymentSessionId,
  });
}

abstract class CashfreeCheckoutPlatform {
  Future<CashfreePaymentSuccess> open(CashfreeCheckoutOptions options);
}
