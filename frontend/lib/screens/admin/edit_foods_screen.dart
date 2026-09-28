import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditFoodsScreen extends StatefulWidget {
  final Map<String, dynamic> food;

  const EditFoodsScreen({
    super.key,
    required this.food,
  });

  @override
  State<EditFoodsScreen> createState() => _EditFoodsScreenState();
}

class _EditFoodsScreenState extends State<EditFoodsScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController imageController;

  bool available = true;
  bool saving = false;

  final String baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.food['name']?.toString() ?? '',
    );

    priceController = TextEditingController(
      text: widget.food['price']?.toString() ?? '',
    );

    descriptionController = TextEditingController(
      text: widget.food['description']?.toString() ?? '',
    );

    categoryController = TextEditingController(
      text: widget.food['category']?.toString() ?? '',
    );

    imageController = TextEditingController(
      text: widget.food['image']?.toString() ??
          widget.food['imagePath']?.toString() ??
          '',
    );

    available =
        widget.food['isAvailable'] == true ||
        widget.food['isAvailable']?.toString() == '1' ||
        widget.food['isAvailable']?.toString() == 'true';
  }

  Future<void> updateFood() async {
    final id = widget.food['id'];
    final name = nameController.text.trim();
    final price = double.tryParse(
      priceController.text.trim(),
    );

    if (name.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid food name and price'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/menu/$id'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'description': descriptionController.text.trim(),
          'category': categoryController.text.trim().isEmpty
              ? 'Other'
              : categoryController.text.trim(),
          'image': imageController.text.trim(),
          'imagePath': imageController.text.trim(),
          'isAvailable': available,
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food updated successfully'),
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  InputDecoration decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Food',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: decoration('Food Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: decoration('Price'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: decoration('Category'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: decoration('Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: imageController,
              decoration: decoration('Image URL'),
            ),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Available',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: available,
                onChanged: (value) {
                  setState(() {
                    available = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : updateFood,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  saving ? 'Saving...' : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}