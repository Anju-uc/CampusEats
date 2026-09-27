import 'dart:async';

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _sessionKey;
  bool _backendMode = false;
  String? _error;

  List<CartItem> get items => List.unmodifiable(_items);
  String? get error => _error;

  Future<void> switchSession(
    String sessionKey, {
    bool useBackend = false,
  }) async {
    _sessionKey = sessionKey;
    _backendMode = useBackend;
    _items.clear();
    _error = null;
    notifyListeners();

    if (_backendMode) {
      try {
        final backendItems = await ApiService.getCart();
        _items.addAll(
          backendItems.map(
            (item) => CartItem(
              backendMenuItemId: item['menuItemId']?.toString(),
              name: item['name']?.toString() ?? 'Menu item',
              image: item['imageUrl']?.toString() ?? '',
              price: double.tryParse(item['price']?.toString() ?? '') ?? 0,
              quantity: int.tryParse(item['quantity']?.toString() ?? '') ?? 1,
            ),
          ),
        );
      } catch (error) {
        _error = error.toString();
      }
      notifyListeners();
    }
  }

  void clearSession() {
    _sessionKey = null;
    _backendMode = false;
    _items.clear();
    _error = null;
    notifyListeners();
  }

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

  bool addItem(CartItem item) {
    if (_items.isNotEmpty && _items.first.cafeteria != item.cafeteria) {
      return false;
    }

    final index = _items.indexWhere(
      (existing) =>
          existing.name == item.name && existing.cafeteria == item.cafeteria,
    );

    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }

    if (_backendMode && item.backendMenuItemId != null) {
      unawaited(
        ApiService.addCartItem(item.backendMenuItemId!, item.quantity)
            .catchError((error) {
          _error = error.toString();
          notifyListeners();
        }),
      );
    }

    notifyListeners();
    return true;
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void removeItem(CartItem item) {
    _items.remove(item);
    if (_backendMode && item.backendMenuItemId != null) {
      unawaited(
        ApiService.removeCartItem(item.backendMenuItemId!).catchError((error) {
          _error = error.toString();
          notifyListeners();
        }),
      );
    }
    notifyListeners();
  }

  // ============================================================
  // INCREASE
  // ============================================================

  void increaseQuantity(CartItem item) {
    item.quantity++;
    if (_backendMode && item.backendMenuItemId != null) {
      unawaited(
        ApiService.updateCartItem(item.backendMenuItemId!, item.quantity)
            .catchError((error) {
          _error = error.toString();
          notifyListeners();
        }),
      );
    }
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

    if (_backendMode && item.backendMenuItemId != null) {
      if (_items.contains(item)) {
        unawaited(
          ApiService.updateCartItem(item.backendMenuItemId!, item.quantity)
              .catchError((error) {
            _error = error.toString();
            notifyListeners();
          }),
        );
      } else {
        unawaited(
          ApiService.removeCartItem(item.backendMenuItemId!).catchError((error) {
            _error = error.toString();
            notifyListeners();
          }),
        );
      }
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearCart() {
    _items.clear();
    if (_backendMode) {
      unawaited(ApiService.clearBackendCart().catchError((error) {
        _error = error.toString();
        notifyListeners();
      }));
    }
    notifyListeners();
  }
}
