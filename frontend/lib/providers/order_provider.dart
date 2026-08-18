import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  // ============================================================
  // ORDERS
  // ============================================================

  final List<OrderModel> _orders = [];

  List<OrderModel> get orders =>
      List.unmodifiable(_orders);

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // ============================================================
  // ERROR
  // ============================================================

  String? _error;

  String? get error => _error;

  // ============================================================
  // LOAD ORDERS FROM BACKEND / SQLITE
  // ============================================================

  Future<void> loadOrders() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final data = await ApiService.getOrders();

      _orders.clear();

      for (final item in data) {
        if (item is! Map) {
          continue;
        }

        final order = OrderModel(
          id: item['id'] == null
              ? null
              : int.tryParse(
                  item['id'].toString(),
                ),

          foodName:
              item['foodName']?.toString() ??
              item['food_name']?.toString() ??
              'Unknown Food',

          total:
              double.tryParse(
                item['total']?.toString() ?? '0',
              ) ??
              0.0,

          date:
              item['date']?.toString() ??
              item['createdAt']?.toString() ??
              '',

          status:
              item['status']?.toString() ??
              'Confirmed',
        );

        _orders.add(order);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // ADD ORDER
  // ============================================================
  //
  // Keep this method for existing student checkout code.
  // The actual API call should happen when the order is created.
  //
  // ============================================================

  void addOrder(OrderModel order) {
    _orders.add(order);

    SystemSound.play(
      SystemSoundType.alert,
    );

    notifyListeners();
  }

  // ============================================================
  // GET ORDERS BY STATUS
  // ============================================================

  List<OrderModel> getOrdersByStatus(
    String status,
  ) {
    return _orders
        .where(
          (order) =>
              order.status == status,
        )
        .toList();
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================

  Future<bool> updateOrderStatus(
    OrderModel order,
    String newStatus,
  ) async {
    if (order.id == null) {
      _error = 'Order ID is missing';
      notifyListeners();
      return false;
    }

    try {
      _error = null;

      await ApiService.updateOrderStatus(
        order.id!,
        newStatus,
      );

      order.status = newStatus;

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // MARK READY
  // ============================================================

  Future<bool> markReady(
    int index,
  ) async {
    if (index < 0 ||
        index >= _orders.length) {
      return false;
    }

    final order = _orders[index];

    return await updateOrderStatus(
      order,
      'Ready',
    );
  }

  // ============================================================
  // MARK COLLECTED
  // ============================================================

  Future<bool> markCollected(
    int index,
  ) async {
    if (index < 0 ||
        index >= _orders.length) {
      return false;
    }

    final order = _orders[index];

    return await updateOrderStatus(
      order,
      'Completed',
    );
  }

  // ============================================================
  // MARK PREPARING
  // ============================================================

  Future<bool> markPreparing(
    int index,
  ) async {
    if (index < 0 ||
        index >= _orders.length) {
      return false;
    }

    final order = _orders[index];

    return await updateOrderStatus(
      order,
      'Preparing',
    );
  }

  // ============================================================
  // MARK CONFIRMED
  // ============================================================

  Future<bool> markConfirmed(
    int index,
  ) async {
    if (index < 0 ||
        index >= _orders.length) {
      return false;
    }

    final order = _orders[index];

    return await updateOrderStatus(
      order,
      'Confirmed',
    );
  }

  // ============================================================
  // DELETE ORDER
  // ============================================================

  Future<bool> deleteOrder(
    int index,
  ) async {
    if (index < 0 ||
        index >= _orders.length) {
      return false;
    }

    final order = _orders[index];

    if (order.id == null) {
      _error = 'Order ID is missing';
      notifyListeners();
      return false;
    }

    try {
      _error = null;

      await ApiService.deleteOrder(
        order.id!,
      );

      _orders.removeAt(index);

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // CLEAR ORDERS
  // ============================================================

  void clearOrders() {
    _orders.clear();

    notifyListeners();
  }
}