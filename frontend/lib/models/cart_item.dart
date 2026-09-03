class CartItem {
  final String name;
  final String image;
  final double price;

  // Cafeteria is optional for older screens.
  // New menu screen will provide the actual cafeteria.
  final String cafeteria;

  int quantity;

  CartItem({
    required this.name,
    required this.image,
    required this.price,
    this.cafeteria = "Bengaluru Cafe",
    this.quantity = 1,
  });

  double get totalPrice {
    return price * quantity;
  }
}