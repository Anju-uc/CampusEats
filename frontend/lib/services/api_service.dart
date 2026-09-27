import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'demo_service.dart';

class ApiService {
  static const bool demoMode = true;
  // ============================================================
  // BACKEND URL
  // ============================================================

  // Android Emulator -> PC localhost
  static const String baseUrl = 'http://localhost:5000/api';
  static String? adminEmail;
  static String? adminToken;
  static String? adminCafeteria;
  static String? adminCafeteriaId;
  static String? adminTitle;
  static String? studentId;
  static String? studentUid;
  static String? studentName;
  static String? studentProgram;
  static String? studentStatus;
  static String? studentRole;
  static String? studentToken;
  static String? studentRefreshToken;
  static String? studentExpiresIn;
  static String? facultyId;
  static String? facultyName;
  static String? facultyProgram;
  static String? facultyRole;
  static const _secureStorage = FlutterSecureStorage();

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (studentToken != null)
      'Authorization': 'Bearer $studentToken'
    else if (adminToken != null)
      'Authorization': 'Bearer $adminToken',
  };

  static Future<Map<String, dynamic>> loginStudent(
    String rawStudentId,
    String password,
  ) async {
    final normalizedStudentId = rawStudentId.trim().toUpperCase();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'studentId': normalizedStudentId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final data = decoded is Map<String, dynamic> && decoded['data'] is Map
          ? Map<String, dynamic>.from(decoded['data'] as Map)
          : decoded is Map<String, dynamic>
          ? decoded
          : null;

      if (response.statusCode == 200 && data != null) {
        final idToken = data['idToken']?.toString();
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Login did not return a session token');
        }

        studentId = data['studentId']?.toString() ?? normalizedStudentId;
        studentUid = data['uid']?.toString();
        studentName = data['name']?.toString();
        studentProgram = data['program']?.toString();
        studentStatus = data['status']?.toString();
        studentRole = data['role']?.toString();
        studentToken = idToken;
        studentRefreshToken = data['refreshToken']?.toString();
        studentExpiresIn = data['expiresIn']?.toString();

        await _secureStorage.write(
          key: 'student_id_token',
          value: studentToken,
        );
        await _secureStorage.write(
          key: 'student_refresh_token',
          value: studentRefreshToken ?? '',
        );
        await _secureStorage.write(key: 'student_id', value: studentId ?? '');
        await _secureStorage.write(key: 'student_uid', value: studentUid ?? '');
        await _secureStorage.write(
          key: 'student_name',
          value: studentName ?? '',
        );
        await _secureStorage.write(
          key: 'student_program',
          value: studentProgram ?? '',
        );
        await _secureStorage.write(
          key: 'student_status',
          value: studentStatus ?? '',
        );
        await _secureStorage.write(
          key: 'student_role',
          value: studentRole ?? '',
        );
        await _secureStorage.write(
          key: 'student_expires_in',
          value: studentExpiresIn ?? '',
        );
        return data;
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Student login failed';
      throw Exception(message);
    } on FormatException {
      throw Exception('The server returned an invalid response');
    } on TimeoutException {
      throw Exception('The server took too long to respond');
    } on http.ClientException {
      throw Exception('Unable to reach CampusEATS. Check your connection.');
    }
  }

  static Future<void> registerStudent(
    String rawStudentId,
    String password,
  ) async {
    final normalizedStudentId = rawStudentId.trim().toUpperCase();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'studentId': normalizedStudentId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return;
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Student registration failed';
      throw Exception(message);
    } on FormatException {
      throw Exception('The server returned an invalid response');
    } on TimeoutException {
      throw Exception('The server took too long to respond');
    } on http.ClientException {
      throw Exception('Unable to reach CampusEATS. Check your connection.');
    }
  }

  static Future<bool> restoreStudentSession() async {
    studentToken = await _secureStorage.read(key: 'student_id_token');
    studentRefreshToken = await _secureStorage.read(
      key: 'student_refresh_token',
    );
    studentId = await _secureStorage.read(key: 'student_id');
    studentUid = await _secureStorage.read(key: 'student_uid');
    studentName = await _secureStorage.read(key: 'student_name');
    studentProgram = await _secureStorage.read(key: 'student_program');
    studentStatus = await _secureStorage.read(key: 'student_status');
    studentRole = await _secureStorage.read(key: 'student_role');
    studentExpiresIn = await _secureStorage.read(key: 'student_expires_in');
    return studentToken != null && studentToken!.isNotEmpty;
  }

  static Future<void> loginFaculty(String rawFacultyId) async {
    facultyId = rawFacultyId.trim();
    facultyName = facultyId;
    facultyProgram = 'Faculty';
    facultyRole = 'Faculty';
    await _secureStorage.write(key: 'faculty_id', value: facultyId ?? '');
    await _secureStorage.write(key: 'faculty_name', value: facultyName ?? '');
    await _secureStorage.write(key: 'faculty_program', value: facultyProgram ?? '');
    await _secureStorage.write(key: 'faculty_role', value: facultyRole ?? '');
  }

  static Future<bool> restoreFacultySession() async {
    facultyId = await _secureStorage.read(key: 'faculty_id');
    facultyName = await _secureStorage.read(key: 'faculty_name');
    facultyProgram = await _secureStorage.read(key: 'faculty_program');
    facultyRole = await _secureStorage.read(key: 'faculty_role');
    return facultyId != null && facultyId!.isNotEmpty;
  }

  static Future<void> clearFacultySession() async {
    facultyId = null;
    facultyName = null;
    facultyProgram = null;
    facultyRole = null;
    await Future.wait([
      _secureStorage.delete(key: 'faculty_id'),
      _secureStorage.delete(key: 'faculty_name'),
      _secureStorage.delete(key: 'faculty_program'),
      _secureStorage.delete(key: 'faculty_role'),
    ]);
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    if (studentToken == null) {
      throw Exception('Student session is required for the backend cart.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : decoded;
    final items = data is Map ? data['items'] : data;
    return items is List
        ? items.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
  }

  static Future<void> addCartItem(String menuItemId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/items'),
      headers: _headers,
      body: jsonEncode({'menuItemId': menuItemId, 'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update cart: ${response.statusCode}');
    }
  }

  static Future<void> updateCartItem(String menuItemId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cart/items/$menuItemId'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update cart: ${response.statusCode}');
    }
  }

  static Future<void> removeCartItem(String menuItemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/items/$menuItemId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to remove cart item: ${response.statusCode}');
    }
  }

  static Future<void> clearBackendCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart: ${response.statusCode}');
    }
  }

  static Future<void> clearStudentSession() async {
    studentId = null;
    studentUid = null;
    studentName = null;
    studentProgram = null;
    studentStatus = null;
    studentRole = null;
    studentToken = null;
    studentRefreshToken = null;
    studentExpiresIn = null;

    await Future.wait([
      _secureStorage.delete(key: 'student_id_token'),
      _secureStorage.delete(key: 'student_refresh_token'),
      _secureStorage.delete(key: 'student_id'),
      _secureStorage.delete(key: 'student_uid'),
      _secureStorage.delete(key: 'student_name'),
      _secureStorage.delete(key: 'student_program'),
      _secureStorage.delete(key: 'student_status'),
      _secureStorage.delete(key: 'student_role'),
      _secureStorage.delete(key: 'student_expires_in'),
    ]);
  }

  static Future<Map<String, dynamic>> loginAdmin(
    String email,
    String password,
  ) async {
    if (demoMode) {
      final data = DemoService.login(email, password);
      final user = data['user'] as Map;
      adminEmail = email.trim().toLowerCase();
      adminToken = data['token'].toString();
      adminCafeteria = user['cafeteria'].toString();
      adminCafeteriaId = user['cafeteriaId']?.toString();
      adminTitle = user['title'].toString();
      return data;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      adminEmail = email.trim().toLowerCase();
      adminToken = data['token']?.toString();
      if (adminToken == null || adminToken!.isEmpty) {
        throw Exception('Admin login did not return a session token');
      }
      final user = data['user'];
      if (user is Map) {
        adminCafeteria = user['cafeteria']?.toString();
        adminCafeteriaId = user['cafeteriaId']?.toString();
        adminTitle = user['title']?.toString();
      }
      await _secureStorage.write(key: 'admin_token', value: adminToken);
      await _secureStorage.write(key: 'admin_email', value: adminEmail);
      await _secureStorage.write(key: 'admin_cafeteria', value: adminCafeteria);
      await _secureStorage.write(key: 'admin_title', value: adminTitle);
      return data;
    }
    throw Exception(data is Map ? data['message'] : 'Admin login failed');
  }

  static void clearAdminSession() {
    adminEmail = null;
    adminToken = null;
    adminCafeteria = null;
    adminCafeteriaId = null;
    adminTitle = null;
    _secureStorage.delete(key: 'admin_token');
    _secureStorage.delete(key: 'admin_email');
    _secureStorage.delete(key: 'admin_cafeteria');
    _secureStorage.delete(key: 'admin_title');
  }

  static Future<bool> restoreAdminSession() async {
    if (demoMode && adminToken != null && adminToken!.isNotEmpty) {
      return true;
    }
    adminToken = await _secureStorage.read(key: 'admin_token');
    adminEmail = await _secureStorage.read(key: 'admin_email');
    adminCafeteria = await _secureStorage.read(key: 'admin_cafeteria');
    adminCafeteriaId = await _secureStorage.read(key: 'admin_cafeteria_id');
    adminTitle = await _secureStorage.read(key: 'admin_title');
    return adminToken != null && adminToken!.isNotEmpty;
  }

  static void startDemoKitchenSession({String cafeteria = 'Bengaluru Cafe'}) {
    adminEmail = 'kitchen@$cafeteria';
    adminToken = 'demo-kitchen-token';
    adminCafeteria = cafeteria;
    adminCafeteriaId = cafeteria == 'Cafe PESU'
        ? 'pesu'
        : cafeteria == 'Non-Veg Cafeteria'
        ? 'nonveg'
        : 'bengaluru';
    adminTitle = '$cafeteria Kitchen';
  }

  // ============================================================
  // GET MENU
  // ============================================================

  static Future<List<dynamic>> getMenu() async {
    if (demoMode)
      return DemoService.getMenu(
        cafeteria: adminEmail == null ? null : adminCafeteria,
      );
    final response = await http.get(
      Uri.parse('$baseUrl/menu'),
      headers: _headers,
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

    throw Exception('Failed to load menu: ${response.statusCode}');
  }

  // ============================================================
  // ADD MENU ITEM
  // ============================================================

  static Future<Map<String, dynamic>> addMenuItem(
    Map<String, dynamic> food,
  ) async {
    if (demoMode)
      return DemoService.addMenuItem(food, adminCafeteria ?? 'Bengaluru Cafe');
    final response = await http.post(
      Uri.parse('$baseUrl/menu'),
      headers: _headers,
      body: jsonEncode(food),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
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
    if (demoMode)
      return DemoService.updateMenuItem(
        id,
        food,
        adminCafeteria ?? 'Bengaluru Cafe',
      );
    final response = await http.put(
      Uri.parse('$baseUrl/menu/$id'),
      headers: _headers,
      body: jsonEncode(food),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
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

  static Future<Map<String, dynamic>> deleteMenuItem(int id) async {
    if (demoMode)
      return DemoService.deleteMenuItem(id, adminCafeteria ?? 'Bengaluru Cafe');
    final response = await http.delete(
      Uri.parse('$baseUrl/menu/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
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

  static Future<Map<String, dynamic>> updateMenuAvailability(
    int id,
    bool isAvailable,
  ) async {
    if (demoMode)
      return DemoService.updateAvailability(
        id,
        isAvailable,
        adminCafeteria ?? 'Bengaluru Cafe',
      );
    final response = await http.patch(
      Uri.parse('$baseUrl/menu/$id/availability'),
      headers: _headers,
      body: jsonEncode({'isAvailable': isAvailable}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
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
    if (demoMode) {
      return DemoService.cafeterias
          .map((name) => {'id': name, 'name': name})
          .toList();
    }
    final response = await http.get(Uri.parse('$baseUrl/cafeterias'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('cafeterias')) {
        return List<dynamic>.from(data['cafeterias']);
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
  // ============================================================
  // PLACE ORDER
  // ============================================================

  static Future<Map<String, dynamic>> placeOrder(
    Map<String, dynamic> order,
  ) async {
    if (demoMode && studentToken == null) return DemoService.placeOrder(order);
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
      body: jsonEncode(order),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map) {
          return {
            'success': true,
            'order': Map<String, dynamic>.from(data['data'] as Map),
            ...data,
          };
        }
        return data;
      }
    }

    throw Exception(
      'Failed to place order: ${response.statusCode} ${response.body}',
    );
  }

  // ============================================================
  // GET ALL ORDERS
  // ============================================================
  // ============================================================
  // GET ALL ORDERS
  // ============================================================

  static Future<List<dynamic>> getOrders() async {
    if (demoMode)
      return DemoService.getOrders(adminCafeteria ?? 'Bengaluru Cafe');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map && data.containsKey('orders')) {
          return List<dynamic>.from(data['orders']);
        }

        if (data is List) {
          return data;
        }

        return [];
      }

      throw Exception(
        response.statusCode == 401
            ? _expireAdminSession()
            : 'Failed to load orders: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getStudentOrders() async {
    if (studentToken == null) {
      throw Exception('Student session expired. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : decoded;
      return data is List ? List<dynamic>.from(data) : <dynamic>[];
    }

    if (response.statusCode == 401) {
      await clearStudentSession();
      throw Exception('Student session expired. Please log in again.');
    }

    throw Exception('Failed to load student orders: ${response.statusCode}');
  }

  static Future<List<dynamic>> getStaffOrders() async {
    if (adminToken == null || adminToken!.isEmpty) {
      throw Exception('Staff session expired. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/orders/all'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : decoded;
      return data is List ? List<dynamic>.from(data) : <dynamic>[];
    }

    if (response.statusCode == 401) {
      clearAdminSession();
      throw Exception('Staff session expired. Please log in again.');
    }

    throw Exception('Failed to load staff orders: ${response.statusCode}');
  }

  static String _expireAdminSession() {
    clearAdminSession();
    return 'Admin session expired. Please login again.';
  }

  // ============================================================
  // DEMO ORDERS
  // Used while backend is being developed
  // ============================================================

  static List<dynamic> _demoOrders() {
    return [
      {
        'id': 1001,
        'orderId': 'CE1001',
        'studentName': 'Adhya',
        'studentEmail': 'student@pes.edu',
        'status': 'Pending',
        'paymentStatus': 'Paid',
        'totalAmount': 90,
        'cafeteria': 'Main Cafeteria',
        'createdAt': DateTime.now().toIso8601String(),
        'items': [
          {
            'name': 'Masala Dosa',
            'quantity': 1,
            'price': 60,
            'totalPrice': 60,
            'image': 'assets/images/food/masala_dosa.jpg',
          },
          {
            'name': 'Vada',
            'quantity': 1,
            'price': 25,
            'totalPrice': 25,
            'image': 'assets/images/food/vada.jpg',
          },
          {
            'name': 'Coffee',
            'quantity': 1,
            'price': 5,
            'totalPrice': 5,
            'image': 'assets/images/food/coffee.jpg',
          },
        ],
      },

      {
        'id': 1002,
        'orderId': 'CE1002',
        'studentName': 'Rahul',
        'studentEmail': 'rahul@pes.edu',
        'status': 'Preparing',
        'paymentStatus': 'Paid',
        'totalAmount': 120,
        'cafeteria': 'Main Cafeteria',
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 8))
            .toIso8601String(),
        'items': [
          {
            'name': 'Chicken Biryani',
            'quantity': 1,
            'price': 100,
            'totalPrice': 100,
            'image': 'assets/images/food/chicken_biryani.jpg',
          },
          {
            'name': 'Cold Coffee',
            'quantity': 1,
            'price': 20,
            'totalPrice': 20,
            'image': 'assets/images/food/cold_coffee.jpg',
          },
        ],
      },

      {
        'id': 1003,
        'orderId': 'CE1003',
        'studentName': 'Sneha',
        'studentEmail': 'sneha@pes.edu',
        'status': 'Ready',
        'paymentStatus': 'Paid',
        'totalAmount': 70,
        'cafeteria': 'Food Court',
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        'items': [
          {
            'name': 'Idli',
            'quantity': 1,
            'price': 30,
            'totalPrice': 30,
            'image': 'assets/images/food/idli.jpg',
          },
          {
            'name': 'Puri',
            'quantity': 1,
            'price': 40,
            'totalPrice': 40,
            'image': 'assets/images/food/puri.jpg',
          },
        ],
      },

      {
        'id': 1004,
        'orderId': 'CE1004',
        'studentName': 'Arjun',
        'studentEmail': 'arjun@pes.edu',
        'status': 'Completed',
        'paymentStatus': 'Paid',
        'totalAmount': 80,
        'cafeteria': 'Main Cafeteria',
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 30))
            .toIso8601String(),
        'items': [
          {
            'name': 'Bisi Bele Bath',
            'quantity': 1,
            'price': 40,
            'totalPrice': 40,
            'image': 'assets/images/food/bisibele_bath.jpg',
          },
          {
            'name': 'Set Dosa',
            'quantity': 1,
            'price': 40,
            'totalPrice': 40,
            'image': 'assets/images/food/set_dosa.jpg',
          },
        ],
      },
    ];
  }
  // ============================================================
  // UPDATE ORDER STATUS
  // ============================================================
  //
  // IMPORTANT:
  // server.js uses PUT /orders/:id/status
  //
  // ============================================================

  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    if (demoMode)
      return DemoService.updateOrderStatus(
        int.tryParse(orderId) ?? 0,
        status,
        adminCafeteria ?? 'Bengaluru Cafe',
      );
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );

    debugPrint(
      'ORDER STATUS RESPONSE: ${response.statusCode} ${response.body}',
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
    }

    throw Exception(
      response.statusCode == 401
          ? 'Admin session expired. Please login again.'
          : 'Failed to update order status: ${response.statusCode} ${response.body}',
    );
  }

  // ============================================================
  // DELETE ORDER
  // ============================================================

  static Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {'success': true};
      }

      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {'success': true, 'data': data};
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

  static Future<Map<String, dynamic>> getAnalytics() async {
    if (demoMode)
      return DemoService.analytics(adminCafeteria ?? 'Bengaluru Cafe');
    final response = await http.get(
      Uri.parse('$baseUrl/analytics'),
      headers: _headers,
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
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
