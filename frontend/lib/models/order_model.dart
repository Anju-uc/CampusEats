class OrderModel {
  final int? id;
  final String foodName;
  final double total;
  final String date;
  String status;
  final String studentName;
  final String studentEmail;
  final String paymentStatus;
  final String cafeteria;

  OrderModel({
    this.id,
    required this.foodName,
    required this.total,
    required this.date,
    required this.status,
    this.studentName = 'Student',
    this.studentEmail = '',
    this.paymentStatus = 'Paid',
    this.cafeteria = 'Bengaluru Cafe',
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final items = map['items'];
    Map<String, dynamic> firstItem = {};

    if (items is List && items.isNotEmpty && items.first is Map) {
      firstItem = Map<String, dynamic>.from(items.first as Map);
    }

    final name = firstItem['name'] ?? map['foodName'] ?? 'Unknown Food';
    final totalAmount = map['totalAmount'] ?? map['total'] ?? 0.0;
    final dateValue = map['createdAt'] ?? map['date'] ?? '';
    final statusValue = map['status'] ?? 'Confirmed';

    return OrderModel(
      id: int.tryParse((map['id'] ?? map['orderId'] ?? '').toString()),
      foodName: name.toString(),
      total: totalAmount is num
          ? totalAmount.toDouble()
          : double.tryParse(totalAmount.toString()) ?? 0.0,
      date: dateValue.toString(),
      status: statusValue.toString(),
      studentName: map['studentName']?.toString() ?? 'Student',
      studentEmail: map['studentEmail']?.toString() ?? '',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Paid',
      cafeteria: map['cafeteria']?.toString() ?? 'Bengaluru Cafe',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'totalAmount': total,
      'total': total,
      'date': date,
      'createdAt': date,
      'status': status,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'paymentStatus': paymentStatus,
      'cafeteria': cafeteria,
      'items': [
        {
          'name': foodName,
          'price': total,
          'quantity': 1,
          'totalPrice': total,
          'cafeteria': cafeteria,
          'image': '',
        },
      ],
    };
  }
}
