class RazorpayCheckoutOptions {
  final String keyId;
  final int amount; // in paise
  final String currency;
  final String razorpayOrderId;
  final String name;
  final String description;
  final String studentName;
  final String studentEmail;
  final String contact;

  const RazorpayCheckoutOptions({
    required this.keyId,
    required this.amount,
    this.currency = 'INR',
    required this.razorpayOrderId,
    this.name = 'CampusEATS',
    this.description = 'Cafeteria Food Order',
    this.studentName = '',
    this.studentEmail = '',
    this.contact = '',
  });
}

class RazorpayPaymentSuccess {
  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;

  const RazorpayPaymentSuccess({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });
}

abstract class RazorpayCheckoutPlatform {
  Future<RazorpayPaymentSuccess> open(RazorpayCheckoutOptions options);
}
