class DemoService {
  static const cafeterias = <String>[
    'Bengaluru Cafe',
    'Cafe PESU',
    'Non-Veg Cafeteria',
  ];

  static final Map<String, String> _adminCafeterias = {
    'bengaluru@campuseats.com': 'Bengaluru Cafe',
    'pesu@campuseats.com': 'Cafe PESU',
    'nonveg@campuseats.com': 'Non-Veg Cafeteria',
  };

  static final Map<String, double> revenues = {
    'Bengaluru Cafe': 1250,
    'Cafe PESU': 2450,
    'Non-Veg Cafeteria': 1780,
  };

  static final Map<String, List<Map<String, dynamic>>> _menus = {
    'Bengaluru Cafe': [
      _food(1, 'Masala Dosa', 60, 'South Indian'),
      _food(2, 'Idli Vada', 45, 'South Indian'),
      _food(3, 'Filter Coffee', 30, 'Beverages'),
    ],
    'Cafe PESU': [
      _food(11, 'Pasta', 120, 'Fast Food'),
      _food(12, 'Veg Burger', 100, 'Fast Food'),
      _food(13, 'Cold Coffee', 60, 'Beverages'),
    ],
    'Non-Veg Cafeteria': [
      _food(21, 'Chicken Biryani', 150, 'Non Veg'),
      _food(22, 'Chicken 65', 120, 'Non Veg'),
      _food(23, 'Egg Roll', 80, 'Non Veg'),
    ],
  };

  static final Map<String, List<Map<String, dynamic>>> _orders = {
    for (final cafeteria in cafeterias) cafeteria: <Map<String, dynamic>>[],
  };
  static int _nextOrderId = 7001;
  static int _nextMenuId = 100;

  static Map<String, dynamic> login(String email, String password) {
    final normalized = email.trim().toLowerCase();
    final cafeteria = _adminCafeterias[normalized];
    if (cafeteria == null || password != '1234') {
      throw Exception('Invalid admin credentials');
    }
    return {
      'success': true,
      'token': 'demo-token-$normalized',
      'user': {
        'email': normalized,
        'role': 'cafeteria_admin',
        'cafeteria': cafeteria,
        'cafeteriaId': _cafeteriaId(cafeteria),
        'title': '$cafeteria Admin',
      },
    };
  }

  static List<dynamic> getMenu({String? cafeteria}) {
    if (cafeteria == null) {
      return _menus.values.expand((items) => items).toList();
    }
    return List<Map<String, dynamic>>.from(_menus[cafeteria] ?? const []);
  }

  static Map<String, dynamic> addMenuItem(Map<String, dynamic> food, String cafeteria) {
    final item = _food(
      _nextMenuId++,
      food['name']?.toString() ?? 'New Food',
      _number(food['price']),
      food['category']?.toString() ?? 'Other',
      description: food['description']?.toString() ?? '',
      image: food['image']?.toString() ?? '',
    );
    _menus[cafeteria]!.add(item);
    return {'success': true, 'food': Map<String, dynamic>.from(item)};
  }

  static Map<String, dynamic> updateMenuItem(int id, Map<String, dynamic> food, String cafeteria) {
    final items = _menus[cafeteria]!;
    final index = items.indexWhere((item) => item['id'] == id);
    if (index < 0) throw Exception('Food item not found');
    items[index] = {...items[index], ...food, 'id': id, 'cafeteria': cafeteria, 'cafeteriaId': _cafeteriaId(cafeteria)};
    return {'success': true, 'food': Map<String, dynamic>.from(items[index])};
  }

  static Map<String, dynamic> deleteMenuItem(int id, String cafeteria) {
    _menus[cafeteria]!.removeWhere((item) => item['id'] == id);
    return {'success': true};
  }

  static Map<String, dynamic> updateAvailability(int id, bool available, String cafeteria) {
    final item = _menus[cafeteria]!.firstWhere((item) => item['id'] == id);
    item['isAvailable'] = available;
    return {'success': true, 'food': item};
  }

  static Map<String, dynamic> placeOrder(Map<String, dynamic> data) {
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : <Map<String, dynamic>>[];
    if (items.isEmpty) {
      throw Exception('Your cart is empty.');
    }
    final cafeteria = _canonicalCafeteria(
      items.first['cafeteria']?.toString() ?? data['cafeteria']?.toString(),
    );
    for (final item in items) {
      item['cafeteria'] = cafeteria;
      item['cafeteriaName'] = cafeteria;
      item['cafeteriaId'] = _cafeteriaId(cafeteria);
    }
    if (items.isEmpty || items.any((item) => item['cafeteria'] != cafeteria)) {
      throw Exception('Please checkout your current cafeteria order before ordering from another cafeteria.');
    }
    final order = {
      'id': _nextOrderId++,
      'orderId': 'CE${_nextOrderId - 1}',
      'studentName': data['studentName'] ?? 'Student',
      'studentEmail': data['studentEmail'] ?? '',
      'items': items,
      'totalAmount': _number(data['totalAmount']),
      'status': 'Confirmed',
      'paymentStatus': 'Paid',
      'cafeteria': cafeteria,
      'cafeteriaName': cafeteria,
      'cafeteriaId': _cafeteriaId(cafeteria),
      'createdAt': DateTime.now().toIso8601String(),
    };
    _orders.putIfAbsent(cafeteria, () => <Map<String, dynamic>>[]).insert(0, order);
    return {'success': true, 'order': order};
  }

  static List<dynamic> getOrders(String cafeteria) => List<Map<String, dynamic>>.from(_orders[_canonicalCafeteria(cafeteria)] ?? const []);

  static Map<String, dynamic> updateOrderStatus(int id, String status, String cafeteria) {
    final order = (_orders[_canonicalCafeteria(cafeteria)] ?? const <Map<String, dynamic>>[]).cast<Map<String, dynamic>>().firstWhere((item) => item['id'] == id);
    order['status'] = status;
    return {'success': true, 'order': order};
  }

  static Map<String, dynamic> analytics(String cafeteria) {
    final orders = _orders[_canonicalCafeteria(cafeteria)] ?? const <Map<String, dynamic>>[];
    int count(String status) => orders.where((order) => order['status'] == status).length;
    return {
      'success': true,
      'cafeteriaId': _cafeteriaId(cafeteria),
      'cafeteriaName': cafeteria,
      'allTime': {'orders': orders.length, 'revenue': revenues[cafeteria] ?? 0},
      'today': {'orders': orders.length, 'revenue': orders.fold<double>(0, (sum, order) => sum + _number(order['totalAmount']))},
      'status': {'confirmed': count('Confirmed'), 'preparing': count('Preparing'), 'ready': count('Ready'), 'completed': count('Completed')},
    };
  }

  static double _number(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  static String _cafeteriaId(String name) => name == 'Cafe PESU' ? 'cafe_pesu' : name == 'Non-Veg Cafeteria' ? 'nonveg_cafeteria' : 'bengaluru_cafe';
  static String _canonicalCafeteria(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'cafe pesu':
      case 'pesu cafeteria':
        return 'Cafe PESU';
      case 'non-veg cafeteria':
      case 'nonveg cafeteria':
        return 'Non-Veg Cafeteria';
      default:
        return 'Bengaluru Cafe';
    }
  }

  static Map<String, dynamic> _food(int id, String name, double price, String category, {String description = '', String image = ''}) => {
    'id': id,
    'name': name,
    'price': price,
    'description': description,
    'category': category,
    'image': image,
    'imagePath': image,
    'isAvailable': true,
    'cafeteria': name == 'Pasta' || name == 'Veg Burger' || name == 'Cold Coffee' ? 'Cafe PESU' : name == 'Chicken Biryani' || name == 'Chicken 65' || name == 'Egg Roll' ? 'Non-Veg Cafeteria' : 'Bengaluru Cafe',
    'cafeteriaId': name == 'Pasta' || name == 'Veg Burger' || name == 'Cold Coffee' ? 'cafe_pesu' : name == 'Chicken Biryani' || name == 'Chicken 65' || name == 'Egg Roll' ? 'nonveg_cafeteria' : 'bengaluru_cafe',
    'createdAt': DateTime.now().toIso8601String(),
  };
}
