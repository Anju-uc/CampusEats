import 'package:flutter/foundation.dart';

import '../models/food_model.dart';
import '../services/api_service.dart';

class MenuProvider extends ChangeNotifier {
  // ============================================================
  // FOOD LIST
  // ============================================================

  final List<FoodModel> _foods = [];

  List<FoodModel> get foods =>
      List.unmodifiable(_foods);

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
  // LOAD MENU FROM SQLITE / BACKEND
  // ============================================================

  Future<void> loadMenu() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      final data = await ApiService.getMenu();

      _foods.clear();

      for (final item in data) {
        if (item is! Map) {
          continue;
        }

        final food = FoodModel(
          id: item['id'] == null
              ? null
              : int.tryParse(
                  item['id'].toString(),
                ),

          name:
              item['name']?.toString() ??
              'Unknown Food',

          price:
              double.tryParse(
                item['price']?.toString() ?? '0',
              ) ??
              0.0,

          description:
              item['description']?.toString() ??
              '',

          category:
              item['category']?.toString() ??
              'Other',

          imagePath:
              item['imagePath']?.toString() ??
              item['image']?.toString() ??
              '',

          isAvailable:
              item['isAvailable'] == null
                  ? true
                  : item['isAvailable'] == true,
        );

        _foods.add(food);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // ADD FOOD - LOCAL
  // ============================================================
  //
  // AddFoodScreen already saves through ApiService.addMenuItem().
  // This method is kept so existing code doesn't break.
  //
  // ============================================================

  void addFood(FoodModel food) {
    _foods.add(food);

    notifyListeners();
  }

  // ============================================================
  // DELETE FOOD FROM SQLITE
  // ============================================================

  Future<bool> deleteFood(int index) async {
    if (index < 0 ||
        index >= _foods.length) {
      return false;
    }

    final food = _foods[index];

    // A backend ID is required for permanent deletion.
    if (food.id == null) {
      _error = 'Food ID is missing';
      notifyListeners();
      return false;
    }

    try {
      _error = null;

      await ApiService.deleteMenuItem(
        food.id!,
      );

      // Remove only after backend succeeds.
      _foods.removeAt(index);

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // TOGGLE AVAILABILITY IN SQLITE
  // ============================================================

  Future<bool> toggleAvailability(
    int index,
  ) async {
    if (index < 0 ||
        index >= _foods.length) {
      return false;
    }

    final food = _foods[index];

    if (food.id == null) {
      _error = 'Food ID is missing';
      notifyListeners();
      return false;
    }

    // New availability value.
    final newAvailability =
        !food.isAvailable;

    try {
      _error = null;

      await ApiService.updateMenuAvailability(
        food.id!,
        newAvailability,
      );

      // Update only after backend succeeds.
      _foods[index].isAvailable =
          newAvailability;

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // UPDATE FOOD IN SQLITE
  // ============================================================

  Future<bool> updateFood(
    int index, {
    required String name,
    required double price,
    required String description,
    required String category,
  }) async {
    if (index < 0 ||
        index >= _foods.length) {
      return false;
    }

    final oldFood = _foods[index];

    if (oldFood.id == null) {
      _error = 'Food ID is missing';
      notifyListeners();
      return false;
    }

    try {
      _error = null;

      // ========================================================
      // SEND UPDATE TO BACKEND
      // ========================================================

      await ApiService.updateMenuItem(
        oldFood.id!,
        {
          'name': name,
          'price': price,
          'description': description,
          'category': category,

          // IMPORTANT:
          // We keep the existing image.
          // User does NOT need to select a new picture.
          'image': oldFood.imagePath,

          'isAvailable':
              oldFood.isAvailable,
        },
      );

      // ========================================================
      // UPDATE LOCAL OBJECT AFTER BACKEND SUCCESS
      // ========================================================

      _foods[index] = FoodModel(
        id: oldFood.id,

        name: name,
        price: price,
        description: description,
        category: category,

        imagePath: oldFood.imagePath,

        isAvailable:
            oldFood.isAvailable,
      );

      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // CLEAR MENU
  // ============================================================

  void clearMenu() {
    _foods.clear();

    notifyListeners();
  }
}