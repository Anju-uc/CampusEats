import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _sessionKey;
  bool _backendMode = false;
  String? _error;
  static const _storage = FlutterSecureStorage();

  List<CartItem> get items => List.unmodifiable(_items);
  String? get error => _error;
  String? get currentSessionKey => _sessionKey;

  static String _storageKey(String sessionKey) {
    final clean = sessionKey.startsWith('user_cart_')
        ? sessionKey.substring('user_cart_'.length)
        : sessionKey;
    return 'user_cart_$clean';
  }

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
        if (backendItems.isNotEmpty) {
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
          await _persistLocally();
        } else {
          await _restoreFromLocal();
          if (_items.isNotEmpty) {
            unawaited(
              ApiService.syncCart(
                _items
                    .map((e) => {
                          'menuItemId': e.backendMenuItemId ?? e.menuItemId,
                          'name': e.name,
                          'quantity': e.quantity,
                        })
                    .toList(),
              ),
            );
          }
        }
      } catch (error) {
        _error = error.toString();
        // Fallback to local user cart if backend fetch fails
        await _restoreFromLocal();
      }
      notifyListeners();
    } else {
      await _restoreFromLocal();
      notifyListeners();
    }
  }

  Future<void> _restoreFromLocal() async {
    if (_sessionKey == null) return;
    try {
      final key = _storageKey(_sessionKey!);
      final raw = await _storage.read(key: key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _items.clear();
          for (final item in decoded) {
            if (item is Map) {
              _items.add(CartItem.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
    } catch (_) {
      // Ignore corruption; leave cart empty
    }
  }

  Future<void> _persistLocally() async {
    if (_sessionKey == null) return;
    final key = _storageKey(_sessionKey!);
    if (_items.isEmpty) {
      await _storage.delete(key: key);
    } else {
      final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
      await _storage.write(key: key, value: encoded);
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
  void _syncToBackend() {
    if (!_backendMode) return;
    final payload = _items.map((item) => {
      'menuItemId': item.backendMenuItemId ?? item.menuItemId,
      'name': item.name,
      'quantity': item.quantity,
      'price': item.price,
    }).toList();
    unawaited(
      ApiService.syncCart(payload).catchError((error) {
        _error = error.toString();
        notifyListeners();
      }),
    );
  }

  String? get currentCafeteria =>
      _items.isNotEmpty ? _items.first.cafeteria : null;

  bool hasDifferentCafeteria(String? cafeteria) {
    if (_items.isEmpty || cafeteria == null || cafeteria.isEmpty) return false;
    final current = _items.first.cafeteria;
    if (current == null || current.isEmpty) return false;
    return current != cafeteria;
  }

  bool addItem(CartItem item) {
    if (_items.isNotEmpty &&
        _items.first.cafeteria != null &&
        item.cafeteria != null &&
        _items.first.cafeteria != item.cafeteria) {
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

    unawaited(_persistLocally());
    _syncToBackend();

    notifyListeners();
    return true;
  }

  void clearAndAddItem(CartItem item) {
    _items.clear();
    _items.add(item);
    unawaited(_persistLocally());
    _syncToBackend();
    notifyListeners();
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  void removeItem(CartItem item) {
    _items.remove(item);
    unawaited(_persistLocally());
    _syncToBackend();
    notifyListeners();
  }

  // ============================================================
  // INCREASE
  // ============================================================

  void increaseQuantity(CartItem item) {
    item.quantity++;
    unawaited(_persistLocally());
    _syncToBackend();
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

    unawaited(_persistLocally());
    _syncToBackend();
    notifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearCart() {
    _items.clear();
    unawaited(_persistLocally());
    if (_backendMode) {
      unawaited(
        ApiService.clearBackendCart().catchError((error) {
          _error = error.toString();
          notifyListeners();
        }),
      );
    }
    notifyListeners();
  }
}
