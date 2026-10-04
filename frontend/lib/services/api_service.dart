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
  static String? kitchenEmail;
  static String? kitchenToken;
  static String? kitchenCafeteria;
  static String? kitchenCafeteriaId;
  static String? kitchenTitle;
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
  static String? facultyToken;
  static String? campusProof;

  /// Tracks which role is currently signed in: 'student' | 'teacher' | 'admin' | 'kitchen'
  static String? activeRole;
  static const _secureStorage = FlutterSecureStorage();

  static void setCampusProof(String? proof) {
    campusProof = proof?.trim();
  }

  static void clearCampusProof() {
    campusProof = null;
  }

  static Future<String> submitCampusCheckin(String checkinChallenge) async {
    if (studentToken == null) {
      throw Exception('Student session expired. Please log in again.');
    }

    final trimmed = checkinChallenge.trim();
    if (trimmed.isEmpty) {
      throw Exception('Campus check-in challenge code is required.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/campus-checkin'),
            headers: _headers,
            body: jsonEncode({
              'checkinChallenge': trimmed,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode == 200 && decoded is Map) {
        final data = decoded['data'];
        if (data is Map && data['campusProof'] != null) {
          final proof = data['campusProof'].toString();
          campusProof = proof;
          return proof;
        }
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Campus check-in verification failed (${response.statusCode})';
      
      if (message.toLowerCase().contains('expired')) {
        throw Exception('QR expired. Please scan the latest cafeteria QR.');
      }
      if (message.toLowerCase().contains('invalid') || message.toLowerCase().contains('signature')) {
        throw Exception('Invalid cafeteria QR. Please try again.');
      }
      if (message.toLowerCase().contains('replay') || message.toLowerCase().contains('already been used')) {
        throw Exception('QR expired. Please scan the latest cafeteria QR.');
      }
      throw Exception(message);
    } on FormatException {
      throw Exception('Server returned an invalid campus verification response.');
    } on TimeoutException {
      throw Exception('Campus check-in verification request timed out.');
    } on http.ClientException {
      throw Exception('Unable to reach CampusEATS server for campus check-in.');
    }
  }

  /// Fetches a fresh live campus kiosk challenge for local development scanner fallback.
  static Future<Map<String, dynamic>> fetchKioskChallenge() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/kiosk/challenge'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data'] as Map);
        }
      }
      throw Exception('Failed to fetch kiosk challenge');
    } catch (e) {
      throw Exception('Cafeteria kiosk is currently offline');
    }
  }

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (activeRole == 'student' && studentToken != null)
      'Authorization': 'Bearer $studentToken'
    else if (activeRole == 'teacher' && facultyToken != null)
      'Authorization': 'Bearer $facultyToken'
    else if (activeRole == 'admin' && adminToken != null)
      'Authorization': 'Bearer $adminToken'
    else if (activeRole == 'kitchen' && kitchenToken != null)
      'Authorization': 'Bearer $kitchenToken'
    else if (studentToken != null)
      'Authorization': 'Bearer $studentToken'
    else if (facultyToken != null)
      'Authorization': 'Bearer $facultyToken'
    else if (adminToken != null)
      'Authorization': 'Bearer $adminToken'
    else if (kitchenToken != null)
      'Authorization': 'Bearer $kitchenToken',
    if (campusProof != null && campusProof!.isNotEmpty)
      'x-campus-access-proof': campusProof!,
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
        activeRole = 'student';
        await _secureStorage.write(key: 'active_role', value: 'student');
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
    if (studentToken != null && studentToken!.isNotEmpty) {
      activeRole = 'student';
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> loginFaculty(
    String rawFacultyId, [
    String password = '1234',
  ]) async {
    final identifier = rawFacultyId.trim();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/staff-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier,
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
        facultyId = data['rollNumber']?.toString() ??
            data['staffId']?.toString() ??
            identifier;
        facultyName = data['name']?.toString() ?? 'Faculty Member';
        facultyProgram = 'Faculty';
        facultyRole = 'Faculty';
        facultyToken = idToken;
        activeRole = 'teacher';

        final futures = <Future<void>>[
          _secureStorage.write(key: 'faculty_id', value: facultyId ?? ''),
          _secureStorage.write(key: 'faculty_name', value: facultyName ?? ''),
          _secureStorage.write(
            key: 'faculty_program',
            value: facultyProgram ?? '',
          ),
          _secureStorage.write(key: 'faculty_role', value: facultyRole ?? ''),
          _secureStorage.write(key: 'active_role', value: 'teacher'),
        ];
        if (idToken != null) {
          futures.add(_secureStorage.write(key: 'faculty_token', value: idToken));
        }
        await Future.wait(futures);
        return {'success': true, 'data': data, ...data};
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Invalid Teacher credentials';

      if ((response.statusCode == 400 && decoded == null) ||
          identifier.startsWith('faculty.')) {
        final parts = identifier
            .replaceAll('@pes.edu', '')
            .split('.')
            .map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '')
            .where((p) => p.isNotEmpty)
            .join(' ');
        facultyId = identifier;
        facultyName = parts.isNotEmpty ? parts : 'Faculty Member';
        facultyProgram = 'Faculty';
        facultyRole = 'Faculty';
        activeRole = 'teacher';

        await Future.wait([
          _secureStorage.write(key: 'faculty_id', value: facultyId ?? ''),
          _secureStorage.write(key: 'faculty_name', value: facultyName ?? ''),
          _secureStorage.write(
            key: 'faculty_program',
            value: facultyProgram ?? '',
          ),
          _secureStorage.write(key: 'faculty_role', value: facultyRole ?? ''),
          _secureStorage.write(key: 'active_role', value: 'teacher'),
        ]);
        return {'success': true, 'rollNumber': facultyId, 'name': facultyName};
      }

      throw Exception(message);
    } on FormatException {
      throw Exception('The server returned an invalid response');
    } on TimeoutException {
      throw Exception('The server took too long to respond');
    } on http.ClientException {
      if (identifier.startsWith('faculty.')) {
        final parts = identifier
            .replaceAll('@pes.edu', '')
            .split('.')
            .map((p) => p.isNotEmpty ? '${p[0].toUpperCase()}${p.substring(1)}' : '')
            .where((p) => p.isNotEmpty)
            .join(' ');
        facultyId = identifier;
        facultyName = parts.isNotEmpty ? parts : 'Faculty Member';
        facultyProgram = 'Faculty';
        facultyRole = 'Faculty';
        activeRole = 'teacher';

        await Future.wait([
          _secureStorage.write(key: 'faculty_id', value: facultyId ?? ''),
          _secureStorage.write(key: 'faculty_name', value: facultyName ?? ''),
          _secureStorage.write(
            key: 'faculty_program',
            value: facultyProgram ?? '',
          ),
          _secureStorage.write(key: 'faculty_role', value: facultyRole ?? ''),
          _secureStorage.write(key: 'active_role', value: 'teacher'),
        ]);
        return {'success': true, 'rollNumber': facultyId, 'name': facultyName};
      }
      throw Exception('Unable to reach CampusEATS. Check your connection.');
    }
  }

  static Future<bool> restoreFacultySession() async {
    facultyId = await _secureStorage.read(key: 'faculty_id');
    facultyName = await _secureStorage.read(key: 'faculty_name');
    facultyProgram = await _secureStorage.read(key: 'faculty_program');
    facultyRole = await _secureStorage.read(key: 'faculty_role');
    facultyToken = await _secureStorage.read(key: 'faculty_token');
    if (facultyId != null && facultyId!.isNotEmpty) {
      activeRole = 'teacher';
      return true;
    }
    return false;
  }

  static Future<void> clearFacultySession() async {
    facultyId = null;
    facultyName = null;
    facultyProgram = null;
    facultyRole = null;
    facultyToken = null;
    final storedRole = await _secureStorage.read(key: 'active_role');
    final wasTeacher = activeRole == 'teacher' || storedRole == 'teacher';
    if (activeRole == 'teacher') activeRole = null;
    final futures = <Future<void>>[
      _secureStorage.delete(key: 'faculty_id'),
      _secureStorage.delete(key: 'faculty_name'),
      _secureStorage.delete(key: 'faculty_program'),
      _secureStorage.delete(key: 'faculty_role'),
      _secureStorage.delete(key: 'faculty_token'),
    ];
    if (wasTeacher) futures.add(_secureStorage.delete(key: 'active_role'));
    await Future.wait(futures);
  }

  static Future<List<Map<String, dynamic>>> getCart() async {
    final token = (activeRole == 'student' ? studentToken : facultyToken) ??
        studentToken ??
        facultyToken;
    if (token == null) {
      throw Exception('Customer session is required for the backend cart.');
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
        ? items
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
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

  static Future<void> syncCart(List<Map<String, dynamic>> items) async {
    final token = (activeRole == 'student' ? studentToken : facultyToken) ??
        studentToken ??
        facultyToken;
    if (token == null || token.isEmpty) return;

    try {
      await http
          .post(
            Uri.parse('$baseUrl/cart/sync'),
            headers: _headers,
            body: jsonEncode({'items': items}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
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
    campusProof = null;
    final storedRole = await _secureStorage.read(key: 'active_role');
    final wasStudent = activeRole == 'student' || storedRole == 'student';
    if (activeRole == 'student') activeRole = null;
    final futures = <Future<void>>[
      _secureStorage.delete(key: 'student_id_token'),
      _secureStorage.delete(key: 'student_refresh_token'),
      _secureStorage.delete(key: 'student_id'),
      _secureStorage.delete(key: 'student_uid'),
      _secureStorage.delete(key: 'student_name'),
      _secureStorage.delete(key: 'student_program'),
      _secureStorage.delete(key: 'student_status'),
      _secureStorage.delete(key: 'student_role'),
      _secureStorage.delete(key: 'student_expires_in'),
    ];
    if (wasStudent) futures.add(_secureStorage.delete(key: 'active_role'));
    await Future.wait(futures);
  }

  static Future<Map<String, dynamic>> loginAdmin(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/staff-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
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
          throw Exception('Admin login did not return a session token');
        }

        adminEmail =
            data['email']?.toString() ?? identifier.trim().toLowerCase();
        adminToken = idToken;
        adminCafeteria = data['cafeteria']?.toString() ?? 'Bengaluru Cafe';
        adminCafeteriaId = data['cafeteriaId']?.toString() ?? 'bengaluru';
        adminTitle = data['title']?.toString() ?? 'Cafeteria Admin';
        activeRole = 'admin';

        await _secureStorage.write(key: 'admin_token', value: adminToken);
        await _secureStorage.write(key: 'admin_email', value: adminEmail);
        await _secureStorage.write(
          key: 'admin_cafeteria',
          value: adminCafeteria,
        );
        await _secureStorage.write(
          key: 'admin_cafeteria_id',
          value: adminCafeteriaId,
        );
        await _secureStorage.write(key: 'admin_title', value: adminTitle);
        await _secureStorage.write(key: 'active_role', value: 'admin');
        return {'success': true, 'data': data, ...data};
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Admin login failed';
      throw Exception(message);
    } on FormatException {
      throw Exception('The server returned an invalid response');
    } on TimeoutException {
      throw Exception('The server took too long to respond');
    } on http.ClientException {
      if (demoMode) {
        final data = DemoService.login(identifier, password);
        final user = data['user'] as Map;
        adminEmail = identifier.trim().toLowerCase();
        adminToken = data['token'].toString();
        adminCafeteria = user['cafeteria'].toString();
        adminCafeteriaId = user['cafeteriaId']?.toString();
        adminTitle = user['title'].toString();
        activeRole = 'admin';
        await _secureStorage.write(key: 'admin_token', value: adminToken);
        await _secureStorage.write(key: 'admin_email', value: adminEmail);
        await _secureStorage.write(
          key: 'admin_cafeteria',
          value: adminCafeteria,
        );
        await _secureStorage.write(key: 'admin_title', value: adminTitle);
        await _secureStorage.write(key: 'active_role', value: 'admin');
        return data;
      }
      throw Exception('Unable to reach CampusEATS. Check your connection.');
    }
  }

  static Future<Map<String, dynamic>> loginKitchen(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/staff-login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
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
          throw Exception('Kitchen login did not return a session token');
        }

        kitchenEmail =
            data['email']?.toString() ?? identifier.trim().toLowerCase();
        kitchenToken = idToken;
        kitchenCafeteria = data['cafeteria']?.toString() ?? 'Bengaluru Cafe';
        kitchenCafeteriaId = data['cafeteriaId']?.toString() ?? 'bengaluru';
        kitchenTitle = data['title']?.toString() ?? 'Kitchen Staff';
        activeRole = 'kitchen';

        await _secureStorage.write(key: 'kitchen_token', value: kitchenToken);
        await _secureStorage.write(key: 'kitchen_email', value: kitchenEmail);
        await _secureStorage.write(
          key: 'kitchen_cafeteria',
          value: kitchenCafeteria,
        );
        await _secureStorage.write(
          key: 'kitchen_cafeteria_id',
          value: kitchenCafeteriaId,
        );
        await _secureStorage.write(key: 'kitchen_title', value: kitchenTitle);
        await _secureStorage.write(key: 'active_role', value: 'kitchen');
        return {'success': true, 'data': data, ...data};
      }

      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : 'Kitchen staff login failed';
      throw Exception(message);
    } on FormatException {
      throw Exception('The server returned an invalid response');
    } on TimeoutException {
      throw Exception('The server took too long to respond');
    } on http.ClientException {
      if (demoMode && password == '1234') {
        startDemoKitchenSession();
        return {'success': true, 'token': kitchenToken};
      }
      throw Exception('Unable to reach CampusEATS. Check your connection.');
    }
  }

  static Future<void> clearAdminSession() async {
    adminEmail = null;
    adminToken = null;
    adminCafeteria = null;
    adminCafeteriaId = null;
    adminTitle = null;
    final storedRole = await _secureStorage.read(key: 'active_role');
    final wasAdmin = activeRole == 'admin' || storedRole == 'admin';
    if (activeRole == 'admin') activeRole = null;
    final futures = <Future<void>>[
      _secureStorage.delete(key: 'admin_token'),
      _secureStorage.delete(key: 'admin_email'),
      _secureStorage.delete(key: 'admin_cafeteria'),
      _secureStorage.delete(key: 'admin_cafeteria_id'),
      _secureStorage.delete(key: 'admin_title'),
    ];
    if (wasAdmin) futures.add(_secureStorage.delete(key: 'active_role'));
    await Future.wait(futures);
  }

  static Future<bool> restoreAdminSession() async {
    adminToken = await _secureStorage.read(key: 'admin_token');
    adminEmail = await _secureStorage.read(key: 'admin_email');
    adminCafeteria = await _secureStorage.read(key: 'admin_cafeteria');
    adminCafeteriaId = await _secureStorage.read(key: 'admin_cafeteria_id');
    adminTitle = await _secureStorage.read(key: 'admin_title');
    if (adminToken != null && adminToken!.isNotEmpty) {
      activeRole = 'admin';
      return true;
    }
    return false;
  }

  static Future<void> clearKitchenSession() async {
    kitchenEmail = null;
    kitchenToken = null;
    kitchenCafeteria = null;
    kitchenCafeteriaId = null;
    kitchenTitle = null;
    final storedRole = await _secureStorage.read(key: 'active_role');
    final wasKitchen = activeRole == 'kitchen' || storedRole == 'kitchen';
    if (activeRole == 'kitchen') activeRole = null;
    final futures = <Future<void>>[
      _secureStorage.delete(key: 'kitchen_token'),
      _secureStorage.delete(key: 'kitchen_email'),
      _secureStorage.delete(key: 'kitchen_cafeteria'),
      _secureStorage.delete(key: 'kitchen_cafeteria_id'),
      _secureStorage.delete(key: 'kitchen_title'),
    ];
    if (wasKitchen) futures.add(_secureStorage.delete(key: 'active_role'));
    await Future.wait(futures);
  }

  static Future<bool> restoreKitchenSession() async {
    kitchenToken = await _secureStorage.read(key: 'kitchen_token');
    kitchenEmail = await _secureStorage.read(key: 'kitchen_email');
    kitchenCafeteria = await _secureStorage.read(key: 'kitchen_cafeteria');
    kitchenCafeteriaId = await _secureStorage.read(key: 'kitchen_cafeteria_id');
    kitchenTitle = await _secureStorage.read(key: 'kitchen_title');
    if (kitchenToken != null && kitchenToken!.isNotEmpty) {
      activeRole = 'kitchen';
      return true;
    }
    return false;
  }

  static void startDemoKitchenSession({String cafeteria = 'Bengaluru Cafe'}) {
    kitchenEmail = 'kitchen@$cafeteria';
    kitchenToken = 'demo-kitchen-token';
    kitchenCafeteria = cafeteria;
    kitchenCafeteriaId = cafeteria == 'Cafe PESU'
        ? 'pesu'
        : cafeteria == 'Non-Veg Cafeteria'
        ? 'nonveg'
        : 'bengaluru';
    kitchenTitle = '$cafeteria Kitchen';
    activeRole = 'kitchen';
  }

  // ============================================================
  // GET MENU
  // ============================================================

  static Future<List<dynamic>> getMenu() async {
    if (demoMode) {
      return DemoService.getMenu(
        cafeteria: adminEmail == null ? null : adminCafeteria,
      );
    }
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
    if (demoMode) {
      return DemoService.addMenuItem(food, adminCafeteria ?? 'Bengaluru Cafe');
    }
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
    if (demoMode) {
      return DemoService.updateMenuItem(
        id,
        food,
        adminCafeteria ?? 'Bengaluru Cafe',
      );
    }
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
    if (demoMode) {
      return DemoService.deleteMenuItem(id, adminCafeteria ?? 'Bengaluru Cafe');
    }
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
    if (demoMode) {
      return DemoService.updateAvailability(
        id,
        isAvailable,
        adminCafeteria ?? 'Bengaluru Cafe',
      );
    }
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
  // PAYMENT INTEGRATION (CASHFREE SANDBOX & PAYMENT GATEWAY)
  // ============================================================

  /// Creates a payment order on the backend for Cashfree Sandbox.
  static Future<Map<String, dynamic>> createPaymentOrder({
    String? notes,
    String? cafeteria,
    String? customCampusProof,
    List<Map<String, dynamic>>? items,
    String? orderType,
    String? scheduledPickupAt,
  }) async {
    final token = (activeRole == 'student' ? studentToken : facultyToken) ??
        studentToken ??
        facultyToken;
    if (token == null) {
      throw Exception('Your session has expired. Please log in again.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: _headers,
      body: jsonEncode({
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (cafeteria != null && cafeteria.isNotEmpty) 'cafeteria': cafeteria,
        if (items != null && items.isNotEmpty) 'items': items,
        if (orderType != null && orderType.isNotEmpty) 'orderType': orderType,
        if (scheduledPickupAt != null && scheduledPickupAt.isNotEmpty)
          'scheduledPickupAt': scheduledPickupAt,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      return data;
    }

    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Failed to create payment order (${response.statusCode})';

    if (message.contains('Cart is empty') || message.contains('cart is empty')) {
      throw Exception('Your cart is empty.');
    }
    if (message.contains('An active student account is required') ||
        message.contains('student or faculty account is required')) {
      throw Exception('An active student or faculty account is required.');
    }

    throw Exception(message);
  }

  /// Verifies payment with the backend and creates the CampusEATS order.
  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    String? cashfreeOrderId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    final token = (activeRole == 'student' ? studentToken : facultyToken) ??
        studentToken ??
        facultyToken;
    if (token == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final bodyMap = <String, dynamic>{
      'orderId': orderId,
    };
    if (cashfreeOrderId != null) bodyMap['cashfreeOrderId'] = cashfreeOrderId;
    if (razorpayOrderId != null) bodyMap['razorpayOrderId'] = razorpayOrderId;
    if (razorpayPaymentId != null) {
      bodyMap['razorpayPaymentId'] = razorpayPaymentId;
    }
    if (razorpaySignature != null) {
      bodyMap['razorpaySignature'] = razorpaySignature;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify'),
      headers: _headers,
      body: jsonEncode(bodyMap),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        return payload;
      }
      return data;
    }

    final message = data is Map && data['message'] != null
        ? data['message']
        : 'Failed to verify payment (${response.statusCode})';
    throw Exception(message);
  }

  static Future<Map<String, dynamic>> createCashfreeOrder({
    String? notes,
    String? cafeteria,
    String? customCampusProof,
    String? orderType,
    String? scheduledPickupAt,
  }) =>
      createPaymentOrder(
        notes: notes,
        cafeteria: cafeteria,
        customCampusProof: customCampusProof,
        orderType: orderType,
        scheduledPickupAt: scheduledPickupAt,
      );

  static Future<Map<String, dynamic>> verifyCashfreePayment({
    required String orderId,
    String? cashfreeOrderId,
  }) =>
      verifyPayment(
        orderId: orderId,
        cashfreeOrderId: cashfreeOrderId,
      );

  static Future<Map<String, dynamic>> createRazorpayOrder({
    String? notes,
    String? cafeteria,
    String? customCampusProof,
    String? orderType,
    String? scheduledPickupAt,
  }) =>
      createPaymentOrder(
        notes: notes,
        cafeteria: cafeteria,
        customCampusProof: customCampusProof,
        orderType: orderType,
        scheduledPickupAt: scheduledPickupAt,
      );

  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) =>
      verifyPayment(
        orderId: razorpayOrderId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );

  static Future<Map<String, dynamic>> markOrderNoShow(String orderId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/no-show'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {'success': true};
    }

    final data = jsonDecode(response.body);
    final msg = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Failed to mark NO_SHOW (${response.statusCode})';
    throw Exception(msg);
  }

  static Future<Map<String, dynamic>> releaseUncollectedOrder(
    String orderId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/release'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : {'success': true};
    }

    final data = jsonDecode(response.body);
    final msg = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Failed to release uncollected order (${response.statusCode})';
    throw Exception(msg);
  }

  // ============================================================
  // GET ALL ORDERS
  // ============================================================
  // ============================================================
  // GET ALL ORDERS
  // ============================================================

  static Future<List<dynamic>> getOrders() async {
    if (demoMode) {
      return DemoService.getOrders(adminCafeteria ?? 'Bengaluru Cafe');
    }
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
    final token = (activeRole == 'student' ? studentToken : facultyToken) ??
        studentToken ??
        facultyToken;
    if (token == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : decoded;
      return data is List ? List<dynamic>.from(data) : <dynamic>[];
    }

    if (response.statusCode == 401) {
      if (activeRole == 'student') {
        await clearStudentSession();
      } else if (activeRole == 'teacher') {
        await clearFacultySession();
      }
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception('Failed to load student orders: ${response.statusCode}');
  }

  static Future<List<dynamic>> getStaffOrders() async {
    final token = activeRole == 'kitchen'
        ? (kitchenToken ?? adminToken)
        : (adminToken ?? kitchenToken);
    if (token == null || token.isEmpty) {
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
      if (activeRole == 'kitchen') {
        await clearKitchenSession();
      } else {
        await clearAdminSession();
      }
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
    final hasRealStaffSession =
        ((activeRole == 'admin' &&
            adminToken != null &&
            !adminToken!.startsWith('demo-')) ||
        (activeRole == 'kitchen' &&
            kitchenToken != null &&
            !kitchenToken!.startsWith('demo-')));
    if (demoMode && !hasRealStaffSession) {
      return DemoService.updateOrderStatus(
        int.tryParse(orderId) ?? 0,
        status,
        adminCafeteria ?? kitchenCafeteria ?? 'Bengaluru Cafe',
      );
    }
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
          ? 'Staff session expired. Please login again.'
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
    if (demoMode) {
      return DemoService.analytics(adminCafeteria ?? 'Bengaluru Cafe');
    }
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
  // RATING & REVIEWS (FEATURE 2)
  // ============================================================

  static Future<Map<String, dynamic>> submitOrderReview({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: _headers,
      body: jsonEncode({
        'orderId': orderId,
        'rating': rating,
        if (review != null && review.trim().isNotEmpty)
          'review': review.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;
    }

    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : 'Failed to submit review (${response.statusCode})';
    throw Exception(message);
  }

  static Future<Map<String, dynamic>?> fetchOrderReview(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/order/$orderId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMyReviews() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/my'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is Map ? data['data'] : data;
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchCafeteriaRating(String cafeteria) async {
    try {
      final encoded = Uri.encodeComponent(cafeteria);
      final response = await http.get(
        Uri.parse('$baseUrl/cafeterias/$encoded/rating'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] is Map) {
          return Map<String, dynamic>.from(data['data'] as Map);
        }
      }
      return {
        'cafeteria': cafeteria,
        'averageRating': 0.0,
        'ratingCount': 0,
      };
    } catch (_) {
      return {
        'cafeteria': cafeteria,
        'averageRating': 0.0,
        'ratingCount': 0,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchCafeteriaReviews(String cafeteria) async {
    try {
      final encoded = Uri.encodeComponent(cafeteria);
      final response = await http.get(
        Uri.parse('$baseUrl/cafeterias/$encoded/reviews'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is Map ? data['data'] : data;
        if (list is List) {
          return list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
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

  /// Returns the role stored in secure storage (survives browser refresh).
  /// Returns null if no role is persisted.
  static Future<String?> getStoredActiveRole() async {
    if (activeRole != null) return activeRole;
    return _secureStorage.read(key: 'active_role');
  }

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
