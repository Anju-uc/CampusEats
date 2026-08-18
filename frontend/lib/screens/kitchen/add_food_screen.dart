import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  final ImagePicker _picker = ImagePicker();

  String selectedImagePath = "";

  // ============================================================
  // CATEGORY
  // ============================================================

  String selectedCategory = "South Indian";

  // ============================================================
  // LOADING
  // ============================================================

  bool isSaving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SELECT IMAGE
  // ============================================================

  Future<void> selectFoodImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImagePath = image.path;
      });
    }
  }

  // ============================================================
  // SAVE FOOD
  // ============================================================

  Future<void> saveFood() async {
    // ==========================================================
    // FOOD NAME
    // ==========================================================

    if (nameController.text.trim().isEmpty) {
      showMessage("Please enter food name");
      return;
    }

    // ==========================================================
    // PRICE
    // ==========================================================

    if (priceController.text.trim().isEmpty) {
      showMessage("Please enter food price");
      return;
    }

    final double? price = double.tryParse(
      priceController.text.trim(),
    );

    if (price == null) {
      showMessage("Please enter a valid price");
      return;
    }

    // ==========================================================
    // DESCRIPTION
    // ==========================================================

    if (descriptionController.text.trim().isEmpty) {
      showMessage("Please enter food description");
      return;
    }

    // ==========================================================
    // IMAGE IS OPTIONAL
    // ==========================================================
    //
    // We intentionally DO NOT stop the user if there is
    // no image selected.
    //
    // image will simply be "" when no image is selected.
    //
    // ==========================================================

    setState(() {
      isSaving = true;
    });

    try {
      // ========================================================
      // FOOD OBJECT
      // ========================================================

      final Map<String, dynamic> food = {
        "name": nameController.text.trim(),
        "price": price,
        "description": descriptionController.text.trim(),
        "category": selectedCategory,

        // Image is optional.
        "image": selectedImagePath,
      };

      // ========================================================
      // SEND TO BACKEND
      // ========================================================

      final result = await ApiService.addMenuItem(food);

      if (!mounted) return;

      // ========================================================
      // SUCCESS
      // ========================================================

      if (result["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${food["name"]} added successfully!",
            ),
            backgroundColor: Colors.green,
          ),
        );

        clearForm();
      } else {
        showMessage(
          result["message"] ??
              "Failed to add food",
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to add food: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

  // ============================================================
  // CLEAR FORM
  // ============================================================

  void clearForm() {
    nameController.clear();
    priceController.clear();
    descriptionController.clear();

    setState(() {
      selectedCategory = "South Indian";
      selectedImagePath = "";
    });
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add New Food",
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // FOOD IMAGE
            // ==================================================

            Center(
              child: selectedImagePath.isEmpty
                  ? const CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.orange,

                      child: Icon(
                        Icons.fastfood,
                        color: Colors.white,
                        size: 50,
                      ),
                    )
                  : ClipRRect(
                      borderRadius:
                          BorderRadius.circular(20),

                      child: Image.file(
                        File(selectedImagePath),

                        width: 150,
                        height: 150,

                        fit: BoxFit.cover,
                      ),
                    ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // IMAGE BUTTON
            // ==================================================

            Center(
              child: ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : selectFoodImage,

                icon: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                ),

                label: Text(
                  selectedImagePath.isEmpty
                      ? "Select Food Image"
                      : "Change Food Image",

                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // IMAGE OPTIONAL MESSAGE
            // ==================================================

            const Center(
              child: Text(
                "Food image is optional",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // FOOD NAME
            // ==================================================

            TextField(
              controller: nameController,
              enabled: !isSaving,

              decoration: const InputDecoration(
                labelText: "Food Name",
                hintText:
                    "Example: Chicken Biryani",

                border: OutlineInputBorder(),

                prefixIcon: Icon(
                  Icons.fastfood,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // PRICE
            // ==================================================

            TextField(
              controller: priceController,
              enabled: !isSaving,

              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: const InputDecoration(
                labelText: "Price",
                hintText: "Example: 120",

                border: OutlineInputBorder(),

                prefixIcon: Icon(
                  Icons.currency_rupee,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            TextField(
              controller:
                  descriptionController,

              enabled: !isSaving,

              maxLines: 4,

              decoration: const InputDecoration(
                labelText: "Description",
                hintText:
                    "Enter food description",

                border: OutlineInputBorder(),

                prefixIcon: Icon(
                  Icons.description,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CATEGORY
            // ==================================================

            DropdownButtonFormField<String>(
              initialValue:
                  selectedCategory,

              decoration:
                  const InputDecoration(
                labelText: "Category",

                border:
                    OutlineInputBorder(),

                prefixIcon: Icon(
                  Icons.category,
                ),
              ),

              items: const [
                DropdownMenuItem(
                  value: "South Indian",
                  child:
                      Text("South Indian"),
                ),

                DropdownMenuItem(
                  value: "North Indian",
                  child:
                      Text("North Indian"),
                ),

                DropdownMenuItem(
                  value: "Chinese",
                  child:
                      Text("Chinese"),
                ),

                DropdownMenuItem(
                  value: "Non Veg",
                  child:
                      Text("Non Veg"),
                ),

                DropdownMenuItem(
                  value: "Fast Food",
                  child:
                      Text("Fast Food"),
                ),

                DropdownMenuItem(
                  value: "Beverages",
                  child:
                      Text("Beverages"),
                ),
              ],

              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory =
                              value;
                        });
                      }
                    },
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SAVE FOOD BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : saveFood,

                icon: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),

                label: Text(
                  isSaving
                      ? "ADDING FOOD..."
                      : "SAVE FOOD",

                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // CLEAR BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,

              child: OutlinedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : clearForm,

                icon: const Icon(
                  Icons.clear,
                ),

                label: const Text(
                  "CLEAR",
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      Colors.orange,

                  side:
                      const BorderSide(
                    color: Colors.orange,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}