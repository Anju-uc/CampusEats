class FoodModel {
  final int? id;

  final String name;
  final double price;
  final String description;
  final String category;
  final String cafeteria;
  final String imagePath;

  bool isAvailable;

  FoodModel({
    this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.cafeteria = 'Bengaluru Cafe',
    this.imagePath = '',
    this.isAvailable = true,
  });
}
