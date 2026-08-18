import 'package:flutter/material.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items =>
      List.unmodifiable(_items);

  // ============================================================
  // NUMBER OF ITEMS
  // ============================================================

  int get itemCount {
    int count = 0;

    for (final item in _items) {
      count += item.quantity;
    }

    return count;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalAmount {
    double total = 0;

    for (final item in _items) {
      total += item.totalPrice;
    }

    return total;
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  void addItem(CartItem item) {
    final index = _items.indexWhere(
      (existing) =>
          existing.name == item.name &&
          existing.cafeteria == item.cafeteria,
    );

    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }

    notifyListeners();
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // ============================================================
  // INCREASE
  // ============================================================

  void increaseQuantity(CartItem item) {
    item.quantity++;
    notifyListeners();
  }

  // ============================================================
  // DECREASE
  // ============================================================

  void decreaseQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}