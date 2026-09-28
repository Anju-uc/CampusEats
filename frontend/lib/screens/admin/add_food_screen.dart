import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final imageController = TextEditingController();

  bool available = true;
  bool saving = false;

  final String baseUrl = 'http://localhost:5000';

  Future<void> addFood() async {
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
      final response = await http.post(
        Uri.parse('$baseUrl/menu'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'price': price,
          'description':
              descriptionController.text.trim(),
          'category':
              categoryController.text.trim().isEmpty
                  ? 'Other'
                  : categoryController.text.trim(),
          'image':
              imageController.text.trim(),
          'imagePath':
              imageController.text.trim(),
          'isAvailable': available,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Food added successfully'),
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
          content: Text('Failed to add food: $e'),
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

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    imageController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Food',
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
                subtitle: Text(
                  available
                      ? 'Food is available for ordering'
                      : 'Food is currently unavailable',
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
                onPressed: saving ? null : addFood,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  saving ? 'Adding...' : 'Add Food',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}