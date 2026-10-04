class OrderModel {
  final dynamic id;
  final String foodName;
  final double total;
  final double subtotal;
  final double gst;
  final double pickupFee;
  final String date;
  String status;
  final String studentName;
  final String studentEmail;
  final String paymentStatus;
  final String cafeteria;
  final String orderType;
  final String userType;
  final String? scheduledPickupAt;
  final String? pickupWindowEndAt;
  final String? preparationStartAt;
  final String? noShowAt;
  String pickupStatus;
  final List<dynamic> items;

  OrderModel({
    this.id,
    required this.foodName,
    required this.total,
    double? subtotal,
    this.gst = 3.0,
    this.pickupFee = 0.0,
    required this.date,
    required this.status,
    this.studentName = 'Student',
    this.studentEmail = '',
    this.paymentStatus = 'Paid',
    this.cafeteria = 'Bengaluru Cafe',
    this.orderType = 'ASAP',
    this.userType = 'Student',
    this.scheduledPickupAt,
    this.pickupWindowEndAt,
    this.preparationStartAt,
    this.noShowAt,
    this.pickupStatus = 'NOT_SCHEDULED',
    this.items = const [],
  }) : subtotal = subtotal ?? (total >= 3.0 ? (total - 3.0) : total);

  bool get isScheduled => orderType == 'SCHEDULED';
  bool get isFaculty => userType == 'Faculty';

  bool get isCollected =>
      status.toUpperCase() == 'COMPLETED' ||
      status.toUpperCase() == 'COLLECTED' ||
      pickupStatus.toUpperCase() == 'COLLECTED';

  bool get isCancelled =>
      status.toUpperCase() == 'CANCELLED' ||
      pickupStatus.toUpperCase() == 'CANCELLED';

  bool get canBeRated => isCollected && !isCancelled;

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    Map<String, dynamic> firstItem = {};
    List<dynamic> itemsList = [];

    if (rawItems is List && rawItems.isNotEmpty) {
      itemsList = rawItems;
      if (rawItems.first is Map) {
        firstItem = Map<String, dynamic>.from(rawItems.first as Map);
      }
    }

    final name = firstItem['name'] ?? map['foodName'] ?? 'Unknown Food';
    final totalAmount = map['totalAmount'] ?? map['total'] ?? 0.0;
    final parsedTotal = totalAmount is num
        ? totalAmount.toDouble()
        : double.tryParse(totalAmount.toString()) ?? 0.0;

    final rawSubtotal = map['subtotal'] ?? map['itemsTotal'];
    final parsedSubtotal = rawSubtotal is num
        ? rawSubtotal.toDouble()
        : double.tryParse(rawSubtotal?.toString() ?? '') ??
            (parsedTotal >= 3.0 ? (parsedTotal - 3.0) : parsedTotal);

    final rawGst = map['gst'];
    final parsedGst = rawGst is num
        ? rawGst.toDouble()
        : double.tryParse(rawGst?.toString() ?? '') ?? 3.0;

    final rawPickupFee = map['pickupFee'];
    final parsedPickupFee = rawPickupFee is num
        ? rawPickupFee.toDouble()
        : double.tryParse(rawPickupFee?.toString() ?? '') ?? 0.0;

    final dateValue = map['createdAt'] ?? map['date'] ?? '';
    final statusValue = map['status'] ?? 'Confirmed';
    final rawId = map['_id'] ?? map['id'] ?? map['orderId'];

    final rawUserType = (map['userType'] ??
            map['customerType'] ??
            (map['userRole'] == 'Faculty' || map['role'] == 'Faculty'
                ? 'Faculty'
                : 'Student'))
        .toString();
    final rawCustomerName = (map['customerName'] ??
            map['userName'] ??
            map['studentName'] ??
            (rawUserType == 'Faculty' ? 'Faculty Member' : 'Student'))
        .toString();

    return OrderModel(
      id: rawId,
      foodName: name.toString(),
      total: parsedTotal,
      subtotal: parsedSubtotal,
      gst: parsedGst,
      pickupFee: parsedPickupFee,
      date: dateValue.toString(),
      status: statusValue.toString(),
      studentName: rawCustomerName,
      studentEmail: map['studentEmail']?.toString() ?? '',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Paid',
      cafeteria: map['cafeteria']?.toString() ?? 'Bengaluru Cafe',
      orderType: map['orderType']?.toString() ?? 'ASAP',
      userType: rawUserType,
      scheduledPickupAt: map['scheduledPickupAt']?.toString(),
      pickupWindowEndAt: map['pickupWindowEndAt']?.toString(),
      preparationStartAt: map['preparationStartAt']?.toString(),
      noShowAt: map['noShowAt']?.toString(),
      pickupStatus: map['pickupStatus']?.toString() ??
          (map['orderType'] == 'SCHEDULED' ? 'UPCOMING' : 'NOT_SCHEDULED'),
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'totalAmount': total,
      'total': total,
      'subtotal': subtotal,
      'itemsTotal': subtotal,
      'gst': gst,
      'pickupFee': pickupFee,
      'date': date,
      'createdAt': date,
      'status': status,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'paymentStatus': paymentStatus,
      'cafeteria': cafeteria,
      'orderType': orderType,
      'scheduledPickupAt': scheduledPickupAt,
      'pickupWindowEndAt': pickupWindowEndAt,
      'preparationStartAt': preparationStartAt,
      'noShowAt': noShowAt,
      'pickupStatus': pickupStatus,
      'items': items.isNotEmpty
          ? items
          : [
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
