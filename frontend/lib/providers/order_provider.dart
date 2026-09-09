import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<Map<String, dynamic>> get orders => List.unmodifiable(_orders);

  bool get isLoading => _isLoading;

  String? get error => _error;

  static String normalizeStatus(String? status) {
    final value = status?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Confirmed';
    }

    switch (value.toLowerCase()) {
      case 'pending':
      case 'new':
        return 'Confirmed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
      case 'ready for pickup':
      case 'ready_for_pickup':
        return 'Ready';
      case 'completed':
      case 'picked up':
      case 'picked_up':
        return 'Completed';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return value;
    }
  }

  static String normalizeText(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (ApiService.adminToken == null) {
        await ApiService.restoreAdminSession();
      }
      final result = await ApiService.getOrders();

      debugPrint('======================================');
      debugPrint('RAW ORDERS RESULT: $result');
      debugPrint('======================================');

      _orders = result
          .whereType<Map>()
          .map<Map<String, dynamic>>(
            (order) => Map<String, dynamic>.from(order),
          )
          .toList();

      debugPrint('ORDERS LOADED: ${_orders.length}');

      for (final order in _orders) {
        debugPrint('ORDER ID: ${order['id']}');
        debugPrint('ORDER ITEMS: ${order['items']}');
        debugPrint('ORDER TOTAL: ${order['totalAmount']}');
        debugPrint('ORDER STATUS: ${order['status']}');
      }

      debugPrint('======================================');
    } catch (e) {
      _error = e.toString();

      debugPrint('======================================');
      debugPrint('ORDER LOAD ERROR: $e');
      debugPrint('======================================');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GET ORDER ID
  // ============================================================

  int getOrderId(Map<String, dynamic> order) {
    final id = order['id'] ?? order['orderId'];

    if (id is int) {
      return id;
    }

    if (id is num) {
      return id.toInt();
    }

    return int.tryParse(id?.toString() ?? '') ?? 0;
  }

  // ============================================================
  // GET FOOD NAME
  // ============================================================

  String getFoodName(Map<String, dynamic> order) {
    final items = order['items'];

    if (items is List && items.isNotEmpty) {
      for (final item in items) {
        if (item is Map) {
          final name = item['name'] ?? item['foodName'];

          if (name != null) {
            final foodName = name.toString().trim();

            if (foodName.isNotEmpty) {
              return foodName;
            }
          }
        }
      }
    }

    final foodName = order['foodName'];

    if (foodName != null && foodName.toString().trim().isNotEmpty) {
      return foodName.toString().trim();
    }

    final directName = order['name'];
    if (directName != null && directName.toString().trim().isNotEmpty) {
      return directName.toString().trim();
    }

    return 'Unknown Food';
  }

  // ============================================================
  // GET ALL ITEMS
  // ============================================================

  List<Map<String, dynamic>> getItems(Map<String, dynamic> order) {
    final items = order['items'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ============================================================
  // GET TOTAL AMOUNT
  // ============================================================

  double getTotalAmount(Map<String, dynamic> order) {
    final amount =
        order['totalAmount'] ?? order['total_amount'] ?? order['total'];

    if (amount is num) {
      return amount.toDouble();
    }

    final parsed = double.tryParse(amount?.toString() ?? '');

    if (parsed != null) {
      return parsed;
    }

    // Fallback: calculate total from items
    final items = getItems(order);

    double total = 0;

    for (final item in items) {
      total += getItemTotal(item);
    }

    return total;
  }

  // ============================================================
  // GET ITEM PRICE
  // ============================================================

  double getItemPrice(Map<String, dynamic> item) {
    final price = item['price'] ?? item['unitPrice'] ?? item['itemPrice'];

    if (price is num) {
      return price.toDouble();
    }

    return double.tryParse(price?.toString() ?? '') ?? 0.0;
  }

  // ============================================================
  // GET ITEM QUANTITY
  // ============================================================

  int getItemQuantity(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? item['qty'];

    if (quantity is num) {
      return quantity.toInt();
    }

    return int.tryParse(quantity?.toString() ?? '') ?? 1;
  }

  // ============================================================
  // GET ITEM TOTAL
  // ============================================================

  double getItemTotal(Map<String, dynamic> item) {
    final total = item['totalPrice'] ?? item['itemTotal'] ?? item['total'];

    if (total is num) {
      return total.toDouble();
    }

    final parsedTotal = double.tryParse(total?.toString() ?? '');

    if (parsedTotal != null) {
      return parsedTotal;
    }

    final price = getItemPrice(item);
    final quantity = getItemQuantity(item);

    return price * quantity;
  }

  // ============================================================
  // GET STATUS
  // ============================================================

  String getStatus(Map<String, dynamic> order) {
    final status = order['status'];

    if (status != null && status.toString().trim().isNotEmpty) {
      return normalizeStatus(status.toString());
    }

    return 'Confirmed';
  }

  // ============================================================
  // GET PAYMENT STATUS
  // ============================================================

  String getPaymentStatus(Map<String, dynamic> order) {
    final paymentStatus = order['paymentStatus'] ?? order['payment_status'];

    if (paymentStatus != null && paymentStatus.toString().trim().isNotEmpty) {
      return paymentStatus.toString();
    }

    return 'Pending';
  }

  // ============================================================
  // GET STUDENT NAME
  // ============================================================

  String getStudentName(Map<String, dynamic> order) {
    final name = order['studentName'] ?? order['student_name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }

    return 'Student';
  }

  // ============================================================
  // GET STUDENT EMAIL
  // ============================================================

  String getStudentEmail(Map<String, dynamic> order) {
    final email = order['studentEmail'] ?? order['student_email'];

    if (email != null && email.toString().trim().isNotEmpty) {
      return email.toString();
    }

    return '';
  }

  // ============================================================
  // GET CAFETERIA
  // ============================================================

  String getCafeteria(Map<String, dynamic> order) {
    final items = getItems(order);

    if (items.isNotEmpty) {
      final cafeteria = items.first['cafeteria'];

      if (cafeteria != null && cafeteria.toString().trim().isNotEmpty) {
        return cafeteria.toString();
      }
    }

    // Also support order-level cafeteria
    final cafeteria = order['cafeteria'];

    if (cafeteria != null && cafeteria.toString().trim().isNotEmpty) {
      return cafeteria.toString();
    }

    final cafeteriaName = order['cafeteriaName'];
    if (cafeteriaName != null && cafeteriaName.toString().trim().isNotEmpty) {
      return cafeteriaName.toString();
    }

    return 'Bengaluru Cafe';
  }

  // ============================================================
  // GET CREATED DATE
  // ============================================================

  String getCreatedAt(Map<String, dynamic> order) {
    final createdAt =
        order['createdAt'] ?? order['created_at'] ?? order['date'];

    if (createdAt != null && createdAt.toString().trim().isNotEmpty) {
      return createdAt.toString();
    }

    return '';
  }

  // ============================================================
  // ADD ORDER
  // ============================================================

  void addOrder(dynamic order) {
    final normalized = _normalizeOrder(order);
    final index = _orders.indexWhere(
      (existing) => getOrderId(existing) == getOrderId(normalized),
    );

    if (index != -1) {
      _orders[index] = normalized;
    } else {
      _orders.insert(0, normalized);
    }

    notifyListeners();
  }

  Map<String, dynamic> _normalizeOrder(dynamic order) {
    if (order is Map<String, dynamic>) {
      return Map<String, dynamic>.from(order);
    }

    if (order is Map) {
      return Map<String, dynamic>.from(order);
    }

    if (order is OrderModel) {
      return {
        'id': order.id ?? DateTime.now().millisecondsSinceEpoch,
        'studentName': order.studentName ?? 'Student',
        'studentEmail': order.studentEmail ?? '',
        'items': [
          {
            'name': order.foodName,
            'price': order.total,
            'quantity': 1,
            'totalPrice': order.total,
            'cafeteria': order.cafeteria,
            'image': '',
          },
        ],
        'totalAmount': order.total,
        'status': order.status,
        'paymentStatus': order.paymentStatus ?? 'Paid',
        'createdAt': order.date,
      };
    }

    throw ArgumentError('Unsupported order type: ${order.runtimeType}');
  }

  Future<void> _syncFromBackend() async {
    await loadOrders();
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<bool> updateOrderStatus(int orderId, String status) async {
    final normalizedStatus = normalizeStatus(status);
    final currentOrder = _orders.cast<Map<String, dynamic>?>().firstWhere(
      (order) => order != null && getOrderId(order) == orderId,
      orElse: () => null,
    );
    final oldStatus = currentOrder == null
        ? 'Unknown'
        : getStatus(currentOrder);

    try {
      debugPrint(
        'ORDER STATUS UPDATE\n'
        'Order ID: $orderId\n'
        'Old Status: $oldStatus\n'
        'New Status: $normalizedStatus',
      );

      final response = await ApiService.updateOrderStatus(
        orderId,
        normalizedStatus,
      );
      debugPrint('ORDER STATUS API RESPONSE: $response');

      final index = _orders.indexWhere((order) => getOrderId(order) == orderId);

      if (index != -1) {
        _orders[index]['status'] = normalizedStatus;
      }

      notifyListeners();

      await _syncFromBackend();

      return true;
    } catch (e) {
      debugPrint('ORDER STATUS UPDATE ERROR: $e');

      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  Future<bool> markReady(int orderIndex) async {
    if (orderIndex < 0 || orderIndex >= _orders.length) {
      return false;
    }

    final orderId = getOrderId(_orders[orderIndex]);
    return updateOrderStatus(orderId, 'Ready');
  }

  Future<bool> markCollected(int orderIndex) async {
    if (orderIndex < 0 || orderIndex >= _orders.length) {
      return false;
    }

    final orderId = getOrderId(_orders[orderIndex]);
    return updateOrderStatus(orderId, 'Completed');
  }

  Future<bool> markPickedUp(int orderIndex) async {
    if (orderIndex < 0 || orderIndex >= _orders.length) {
      return false;
    }

    final orderId = getOrderId(_orders[orderIndex]);
    return updateOrderStatus(orderId, 'Completed');
  }

  // ============================================================
  // DELETE ORDER
  // ============================================================

  Future<bool> deleteOrder(int orderId) async {
    try {
      debugPrint('Deleting order $orderId');

      await ApiService.deleteOrder(orderId);

      _orders.removeWhere((order) => getOrderId(order) == orderId);

      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('ORDER DELETE ERROR: $e');

      _error = e.toString();
      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // REFRESH ORDERS
  // ============================================================

  Future<void> refreshOrders() async {
    await loadOrders();
  }
  // ============================================================
  // GET ORDERS BY STATUS
  // ============================================================

  List<Map<String, dynamic>> getOrdersByStatus(String status) {
    final targetStatus = normalizeStatus(status);

    return _orders.where((order) {
      return getStatus(order) == targetStatus;
    }).toList();
  }

  // ============================================================
  // GET ORDER COUNT BY STATUS
  // ============================================================

  int getOrderCountByStatus(String status) {
    return getOrdersByStatus(status).length;
  }

  // ============================================================
  // GET TOTAL ORDERS
  // ============================================================

  int getTotalOrders() {
    return _orders.length;
  }

  // ============================================================
  // GET PENDING ORDERS
  // ============================================================

  List<Map<String, dynamic>> get pendingOrders {
    return getOrdersByStatus('Pending');
  }

  // ============================================================
  // GET CONFIRMED ORDERS
  // ============================================================

  List<Map<String, dynamic>> get confirmedOrders {
    return getOrdersByStatus('Confirmed');
  }

  // ============================================================
  // GET PREPARING ORDERS
  // ============================================================

  List<Map<String, dynamic>> get preparingOrders {
    return getOrdersByStatus('Preparing');
  }

  // ============================================================
  // GET READY ORDERS
  // ============================================================

  List<Map<String, dynamic>> get readyOrders {
    return getOrdersByStatus('Ready');
  }

  // ============================================================
  // GET COMPLETED ORDERS
  // ============================================================

  List<Map<String, dynamic>> get completedOrders {
    return getOrdersByStatus('Completed');
  }
  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
