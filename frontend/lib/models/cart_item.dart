class CartItem {
  final int? menuItemId;
  final String? backendMenuItemId;
  final String name;
  final String image;
  final double price;

  // Cafeteria is optional for older screens.
  // New menu screen will provide the actual cafeteria.
  final String cafeteria;

  int quantity;

  CartItem({
    this.menuItemId,
    this.backendMenuItemId,
    required this.name,
    required this.image,
    required this.price,
    this.cafeteria = "Bengaluru Cafe",
    this.quantity = 1,
  });

  double get totalPrice {
    return price * quantity;
  }

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId,
    'backendMenuItemId': backendMenuItemId,
    'name': name,
    'image': image,
    'price': price,
    'cafeteria': cafeteria,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    menuItemId: json['menuItemId'] is int
        ? json['menuItemId'] as int
        : int.tryParse(json['menuItemId']?.toString() ?? ''),
    backendMenuItemId: json['backendMenuItemId']?.toString(),
    name: json['name']?.toString() ?? 'Menu item',
    image: json['image']?.toString() ?? '',
    price: (json['price'] is num)
        ? (json['price'] as num).toDouble()
        : (double.tryParse(json['price']?.toString() ?? '') ?? 0.0),
    cafeteria: json['cafeteria']?.toString() ?? 'Bengaluru Cafe',
    quantity: (json['quantity'] is num)
        ? (json['quantity'] as num).toInt()
        : (int.tryParse(json['quantity']?.toString() ?? '') ?? 1),
  );
}
