import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // ============================================================
  // BACKEND URL
  // ============================================================

  // Android Emulator -> PC localhost
  static const String baseUrl = 'http://10.0.2.2:5000';

  // ============================================================
  // GET MENU
  // ============================================================

  static Future<List<dynamic>> getMenu() async {
    final response = await http.get(
      Uri.parse('$baseUrl/menu'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('menu')) {
        return List<dynamic>.from(data['menu']);
      }

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      'Failed to load menu: ${response.statusCode}',
    );
  }

  // ============================================================
  // ADD MENU ITEM
  // ============================================================

  static Future<Map<String, dynamic>> addMenuItem(
    Map<String, dynamic> food,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/menu'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(food),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to add food: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // UPDATE MENU ITEM
  // ============================================================

  static Future<Map<String, dynamic>> updateMenuItem(
    int id,
    Map<String, dynamic> food,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(food),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to update food: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // DELETE MENU ITEM
  // ============================================================

  static Future<Map<String, dynamic>> deleteMenuItem(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {
          'success': true,
        };
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to delete food: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // UPDATE FOOD AVAILABILITY
  // ============================================================

  static Future<Map<String, dynamic>>
      updateMenuAvailability(
    int id,
    bool isAvailable,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/menu/$id/availability',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'isAvailable': isAvailable,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to update availability: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // GET CAFETERIAS
  // ============================================================

  static Future<List<dynamic>> getCafeterias() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cafeterias'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map &&
          data.containsKey('cafeterias')) {
        return List<dynamic>.from(
          data['cafeterias'],
        );
      }

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      'Failed to load cafeterias: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  static Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> order,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to place order: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // GET ALL ORDERS
  // ============================================================

  static Future<List<dynamic>> getOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map &&
          data.containsKey('orders')) {
        return List<dynamic>.from(
          data['orders'],
        );
      }

      if (data is List) {
        return data;
      }

      return [];
    }

    throw Exception(
      'Failed to load orders: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================
  //
  // IMPORTANT:
  // server.js uses PUT /orders/:id/status
  //
  // ============================================================

  static Future<Map<String, dynamic>>
      updateOrderStatus(
    int orderId,
    String status,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/orders/$orderId/status',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {
          'success': true,
        };
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to update order status: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // DELETE ORDER
  // ============================================================

  static Future<Map<String, dynamic>>
      deleteOrder(
    int orderId,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/orders/$orderId',
      ),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {
          'success': true,
        };
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': true,
        'data': data,
      };
    }

    throw Exception(
      'Failed to delete order: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // GET ANALYTICS
  // ============================================================

  static Future<Map<String, dynamic>>
      getAnalytics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {};
    }

    throw Exception(
      'Failed to load analytics: '
      '${response.statusCode} '
      '${response.body}',
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================
  //
  // NOTE:
  // Your current server.js does NOT contain /login yet.
  // This method is kept because your LoginScreen may use it.
  //
  // ============================================================

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {};
    }

    throw Exception(
      'Login failed: '
      '${response.statusCode} '
      '${response.body}',
    );
  }
}