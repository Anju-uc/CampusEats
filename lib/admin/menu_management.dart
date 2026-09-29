import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MenuManagement extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuManagement({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<MenuManagement> createState() => _MenuManagementState();
}

class _MenuManagementState extends State<MenuManagement> {
  final String baseUrl = 'http://localhost:5000';

  List<Map<String, dynamic>> foods = [];
  List<Map<String, dynamic>> filteredFoods = [];

  bool loading = true;
  String selectedCategory = 'All';
  String searchText = '';

  final Map<String, String> foodAssets = {
    'Idli': 'assets/images/food/idli.jpg',
    'Vada': 'assets/images/food/vada.jpg',
    'Masala Dosa': 'assets/images/food/masala_dosa.jpg',
    'Set Dosa': 'assets/images/food/set_dosa.jpg',
    'Puri': 'assets/images/food/puri.jpg',
    'Bisibele Bath': 'assets/images/food/bisibele_bath.jpg',
    'Lemon Rice': 'assets/images/food/lemon_rice.jpg',
    'Chole Bhature': 'assets/images/food/chole_bhature.jpg',
    'Chicken Biryani': 'assets/images/food/chicken_biryani.jpg',
    'Chicken 65': 'assets/images/food/chicken_65.jpg',
    'Pizza': 'assets/images/food/pizza.jpg',
    'Burger': 'assets/images/food/burger.jpg',
    'Noodles': 'assets/images/food/noodles.jpg',
    'Coffee': 'assets/images/food/coffee.jpg',
    'Cold Coffee': 'assets/images/food/cold_coffee.jpg',
    'Masala Puri': 'assets/images/food/masala_puri.jpg',
    'Pani Puri': 'assets/images/food/pani_puri.jpg',
  };

  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  Future<void> fetchFoods() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/menu'),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        dynamic menuData;

        if (decoded is Map<String, dynamic>) {
          menuData = decoded['menu'];
        } else {
          menuData = decoded;
        }

        final List<dynamic> menuList =
            menuData is List ? menuData : <dynamic>[];

        final loadedFoods = menuList
            .map(
              (item) => Map<String, dynamic>.from(item as Map),
            )
            .toList();

        final cafeteriaFoods = loadedFoods.where((food) {
          final cafeteria =
              food['cafeteria']?.toString() ??
              food['restaurant']?.toString() ??
              food['restaurantName']?.toString() ??
              food['cafeteriaName']?.toString();

          if (cafeteria == null || cafeteria.isEmpty) {
            return _foodBelongsToCafeteria(
              food['name']?.toString() ?? '',
            );
          }

          return cafeteria.toLowerCase() ==
              widget.restaurantName.toLowerCase();
        }).toList();

        if (!mounted) {
          return;
        }

        setState(() {
          foods = cafeteriaFoods;
          filteredFoods =
              List<Map<String, dynamic>>.from(cafeteriaFoods);
          loading = false;
        });

        applyFilters();
      } else {
        if (!mounted) {
          return;
        }

        setState(() {
          loading = false;
        });

        showMessage(
          'Failed to load menu. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        loading = false;
      });

      showMessage('Could not connect to backend');
    }
  }

  bool _foodBelongsToCafeteria(String name) {
    final food = name.trim().toLowerCase();

    if (widget.restaurantName == 'Bengaluru Cafe') {
      return [
        'idli',
        'vada',
        'masala dosa',
        'set dosa',
        'puri',
        'bisibele bath',
        'lemon rice',
        'chole bhature',
        'coffee',
        'cold coffee',
        'pani puri',
        'masala puri',
      ].contains(food);
    }

    if (widget.restaurantName == 'Cafe PESU') {
      return [
        'pizza',
        'burger',
        'noodles',
        'pani puri',
        'masala puri',
      ].contains(food);
    }

    if (widget.restaurantName == 'Non-Veg Cafeteria') {
      return [
        'chicken biryani',
        'chicken 65',
      ].contains(food);
    }

    return false;
  }

  void applyFilters() {
    List<Map<String, dynamic>> result =
        List<Map<String, dynamic>>.from(foods);

    if (selectedCategory != 'All') {
      result = result.where((food) {
        return food['category']?.toString() == selectedCategory;
      }).toList();
    }

    if (searchText.trim().isNotEmpty) {
      final search = searchText.trim().toLowerCase();

      result = result.where((food) {
        final name =
            food['name']?.toString().toLowerCase() ?? '';

        final category =
            food['category']?.toString().toLowerCase() ?? '';

        return name.contains(search) ||
            category.contains(search);
      }).toList();
    }

    if (mounted) {
      setState(() {
        filteredFoods = result;
      });
    }
  }

  List<String> get categories {
    final values = foods
        .map(
          (food) => food['category']?.toString() ?? '',
        )
        .where(
          (category) => category.isNotEmpty,
        )
        .toSet()
        .toList();

    values.sort();

    return ['All', ...values];
  }

  String? getAssetForFood(String name) {
    final exact = foodAssets[name];

    if (exact != null) {
      return exact;
    }

    final lowerName = name.trim().toLowerCase();

    for (final entry in foodAssets.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }

    return null;
  }

  bool isAvailable(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().toLowerCase().trim();

    return text == 'true' ||
        text == '1' ||
        text == 'available' ||
        text == 'yes';
  }

  Future<void> toggleAvailability(
    Map<String, dynamic> food,
  ) async {
    final id = food['id'];
    final current = isAvailable(food['isAvailable']);

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/menu/$id/availability'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'isAvailable': !current,
        }),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        await fetchFoods();
      } else {
        showMessage('Could not update availability');
      }
    } catch (e) {
      showMessage('Could not connect to backend');
    }
  }

  Future<void> deleteFood(
    Map<String, dynamic> food,
  ) async {
    final id = food['id'];
    final name =
        food['name']?.toString() ?? 'this food';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Food'),
          content: Text(
            'Delete $name from the menu?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/menu/$id'),
      );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        await fetchFoods();
        showMessage('$name deleted');
      } else {
        showMessage('Could not delete food');
      }
    } catch (e) {
      showMessage('Could not connect to backend');
    }
  }

  Future<void> addFood() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageController = TextEditingController();

    String category = 'South Indian';
    bool available = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Add Food - ${widget.restaurantName}',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Food Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'South Indian',
                            child: Text('South Indian'),
                          ),
                          DropdownMenuItem(
                            value: 'North Indian',
                            child: Text('North Indian'),
                          ),
                          DropdownMenuItem(
                            value: 'Fast Food',
                            child: Text('Fast Food'),
                          ),
                          DropdownMenuItem(
                            value: 'Beverages',
                            child: Text('Beverages'),
                          ),
                          DropdownMenuItem(
                            value: 'Chicken',
                            child: Text('Chicken'),
                          ),
                          DropdownMenuItem(
                            value: 'Biryani',
                            child: Text('Biryani'),
                          ),
                          DropdownMenuItem(
                            value: 'Egg',
                            child: Text('Egg'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Available'),
                        value: available,
                        onChanged: (value) {
                          setDialogState(() {
                            available = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name =
                        nameController.text.trim();

                    final price = double.tryParse(
                      priceController.text.trim(),
                    );

                    if (name.isEmpty || price == null) {
                      showMessage(
                        'Enter a valid name and price',
                      );
                      return;
                    }

                    try {
                      final response = await http.post(
                        Uri.parse('$baseUrl/menu'),
                        headers: {
                          'Content-Type':
                              'application/json',
                        },
                        body: jsonEncode({
                          'name': name,
                          'price': price,
                          'description':
                              descriptionController.text
                                  .trim(),
                          'category': category,
                          'image':
                              imageController.text.trim(),
                          'isAvailable': available,
                          'cafeteria':
                              widget.restaurantName,
                          'restaurantId':
                              widget.restaurantId,
                        }),
                      );

                      if (response.statusCode >= 200 &&
                          response.statusCode < 300) {
                        if (dialogContext.mounted) {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        }
                      } else {
                        showMessage('Could not add food');
                      }
                    } catch (e) {
                      showMessage(
                        'Could not connect to backend',
                      );
                    }
                  },
                  child: const Text('Add Food'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await fetchFoods();
      showMessage('Food added successfully');
    }
  }

  Future<void> editFood(
    Map<String, dynamic> food,
  ) async {
    final nameController = TextEditingController(
      text: food['name']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: food['price']?.toString() ?? '',
    );

    final descriptionController =
        TextEditingController(
      text: food['description']?.toString() ?? '',
    );

    final imageController = TextEditingController(
      text: food['image']?.toString() ?? '',
    );

    String category =
        food['category']?.toString() ??
            'South Indian';

    bool available =
        isAvailable(food['isAvailable']);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Edit Food - ${widget.restaurantName}',
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Food Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: priceController,
                        keyboardType:
                            TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'South Indian',
                            child: Text('South Indian'),
                          ),
                          DropdownMenuItem(
                            value: 'North Indian',
                            child: Text('North Indian'),
                          ),
                          DropdownMenuItem(
                            value: 'Fast Food',
                            child: Text('Fast Food'),
                          ),
                          DropdownMenuItem(
                            value: 'Beverages',
                            child: Text('Beverages'),
                          ),
                          DropdownMenuItem(
                            value: 'Chicken',
                            child: Text('Chicken'),
                          ),
                          DropdownMenuItem(
                            value: 'Biryani',
                            child: Text('Biryani'),
                          ),
                          DropdownMenuItem(
                            value: 'Egg',
                            child: Text('Egg'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              category = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageController,
                        decoration: const InputDecoration(
                          labelText: 'Image URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Available'),
                        value: available,
                        onChanged: (value) {
                          setDialogState(() {
                            available = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name =
                        nameController.text.trim();

                    final price = double.tryParse(
                      priceController.text.trim(),
                    );

                    if (name.isEmpty || price == null) {
                      showMessage(
                        'Enter a valid name and price',
                      );
                      return;
                    }

                    final id = food['id'];

                    try {
                      final response = await http.put(
                        Uri.parse('$baseUrl/menu/$id'),
                        headers: {
                          'Content-Type':
                              'application/json',
                        },
                        body: jsonEncode({
                          'name': name,
                          'price': price,
                          'description':
                              descriptionController.text
                                  .trim(),
                          'category': category,
                          'image':
                              imageController.text.trim(),
                          'isAvailable': available,
                          'cafeteria':
                              widget.restaurantName,
                          'restaurantId':
                              widget.restaurantId,
                        }),
                      );

                      if (response.statusCode >= 200 &&
                          response.statusCode < 300) {
                        if (dialogContext.mounted) {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        }
                      } else {
                        showMessage(
                          'Could not update food',
                        );
                      }
                    } catch (e) {
                      showMessage(
                        'Could not connect to backend',
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await fetchFoods();
      showMessage('Food updated successfully');
    }
  }

  Widget buildImagePlaceholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.restaurant,
        size: 42,
        color: Colors.grey,
      ),
    );
  }

  Widget buildFoodImage(
    Map<String, dynamic> food,
  ) {
    final name =
        food['name']?.toString() ?? '';

    final assetPath =
        getAssetForFood(name);

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return buildImagePlaceholder();
        },
      );
    }

    final backendImage =
        food['image']?.toString() ?? '';

    if (backendImage.startsWith('http://') ||
        backendImage.startsWith('https://')) {
      return Image.network(
        backendImage,
        width: 110,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return buildImagePlaceholder();
        },
      );
    }

    return buildImagePlaceholder();
  }

  Widget buildFoodCard(
    Map<String, dynamic> food,
  ) {
    final name =
        food['name']?.toString() ?? 'Food';

    final category =
        food['category']?.toString() ?? 'Other';

    final price =
        food['price'] ?? 0;

    final available =
        isAvailable(food['isAvailable']);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),
              child: buildFoodImage(food),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: available
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      available
                          ? 'Available'
                          : 'Unavailable',
                      style: TextStyle(
                        color: available
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: available,
                  onChanged: (_) {
                    toggleAvailability(food);
                  },
                ),
                Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () {
                        editFood(food);
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: () {
                        deleteFood(food);
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.restaurantName} - Menu',
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: fetchFoods,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addFood,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Food',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.restaurant,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Managing ${widget.restaurantName}',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            searchText = value;
                            applyFilters();
                          },
                          decoration:
                              InputDecoration(
                            hintText:
                                'Search food...',
                            prefixIcon:
                                const Icon(
                              Icons.search,
                            ),
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      DropdownButton<String>(
                        value: categories
                                .contains(
                          selectedCategory,
                        )
                            ? selectedCategory
                            : 'All',
                        items: categories
                            .map(
                              (category) {
                                return DropdownMenuItem<
                                    String>(
                                  value:
                                      category,
                                  child: Text(
                                    category,
                                  ),
                                );
                              },
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            selectedCategory =
                                value;
                          });

                          applyFilters();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                    child: filteredFoods
                            .isEmpty
                        ? Center(
                            child: Text(
                              'No food items found for ${widget.restaurantName}',
                              textAlign:
                                  TextAlign.center,
                              style:
                                  const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                filteredFoods
                                    .length,
                            itemBuilder:
                                (context,
                                    index) {
                              return buildFoodCard(
                                filteredFoods[
                                    index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
