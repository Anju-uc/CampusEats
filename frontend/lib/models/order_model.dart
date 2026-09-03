class OrderModel {
  final int? id;

  final String foodName;
  final double total;
  final String date;

  String status;

  OrderModel({
    this.id,
    required this.foodName,
    required this.total,
    required this.date,
    required this.status,
  });
}