import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_model.dart';
import '../../providers/menu_provider.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() =>
      _ManageMenuScreenState();
}

class _ManageMenuScreenState
    extends State<ManageMenuScreen> {
  // Keeps track of which food is currently being updated.
  int? _updatingFoodId;

  @override
  void initState() {
    super.initState();

    // Load menu from backend when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadMenu();
    });
  }

  // ============================================================
  // REFRESH MENU
  // ============================================================

  Future<void> _refreshMenu() async {
    await context.read<MenuProvider>().loadMenu();
  }

  // ============================================================
  // TOGGLE AVAILABILITY
  // ============================================================

  Future<void> _toggleAvailability(
    BuildContext context,
    MenuProvider provider,
    FoodModel food,
  ) async {
    if (food.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Food ID is missing. Cannot update availability.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Prevent double click.
    if (_updatingFoodId != null) {
      return;
    }

    final int foodId = food.id!;

    // New value.
    final bool newAvailability =
        !food.isAvailable;

    setState(() {
      _updatingFoodId = foodId;
    });

    try {
      // ========================================================
      // CALL PROVIDER
      // ========================================================

      final int index = provider.foods.indexWhere(
        (item) => item.id == foodId,
      );

      if (index == -1) {
        throw Exception(
          'Food item not found.',
        );
      }

      final bool success =
          await provider.toggleAvailability(index);

      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ??
                  'Failed to update availability.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // ========================================================
      // IMPORTANT
      // LOAD AGAIN FROM BACKEND
      // ========================================================

      await provider.loadMenu();

      if (!mounted) {
        return;
      }

      // ========================================================
      // FIND FOOD AGAIN
      // ========================================================

      FoodModel? updatedFood;

      for (final item in provider.foods) {
        if (item.id == foodId) {
          updatedFood = item;
          break;
        }
      }

      if (updatedFood == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Food was updated but could not be loaded again.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // ========================================================
      // VERIFY BACKEND VALUE
      // ========================================================

      if (updatedFood.isAvailable != newAvailability) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Backend did not save the availability correctly.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedFood.isAvailable
                ? '${updatedFood.name} is now AVAILABLE'
                : '${updatedFood.name} is now UNAVAILABLE',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingFoodId = null;
        });
      }
    }
  }

  // ============================================================
  // DELETE FOOD
  // ============================================================

  Future<void> _deleteFood(
    BuildContext context,
    MenuProvider provider,
    FoodModel food,
  ) async {
    if (food.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Food ID is missing.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Food?',
          ),
          content: Text(
            'Are you sure you want to delete "${food.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final int index = provider.foods.indexWhere(
      (item) => item.id == food.id,
    );

    if (index == -1) {
      return;
    }

    final bool success =
        await provider.deleteFood(index);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${food.name} deleted successfully.'
              : provider.error ??
                  'Failed to delete ${food.name}.',
        ),
        backgroundColor:
            success ? Colors.green : Colors.red,
      ),
    );
  }

  // ============================================================
  // EDIT FOOD
  // ============================================================

  Future<void> _editFood(
    BuildContext context,
    MenuProvider provider,
    FoodModel food,
  ) async {
    if (food.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Food ID is missing.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final nameController =
        TextEditingController(
      text: food.name,
    );

    final priceController =
        TextEditingController(
      text: food.price.toString(),
    );

    final categoryController =
        TextEditingController(
      text: food.category,
    );

    final descriptionController =
        TextEditingController(
      text: food.description,
    );

    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Edit Food',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    TextField(
                      controller:
                          nameController,
                      enabled: !saving,
                      decoration:
                          const InputDecoration(
                        labelText: 'Food Name',
                        prefixIcon:
                            Icon(Icons.fastfood),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          priceController,
                      enabled: !saving,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      decoration:
                          const InputDecoration(
                        labelText: 'Price',
                        prefixIcon:
                            Icon(Icons.currency_rupee),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          categoryController,
                      enabled: !saving,
                      decoration:
                          const InputDecoration(
                        labelText: 'Category',
                        prefixIcon:
                            Icon(Icons.category),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    TextField(
                      controller:
                          descriptionController,
                      enabled: !saving,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Description',
                        prefixIcon:
                            Icon(Icons.description),
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orange,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final name =
                              nameController
                                  .text
                                  .trim();

                          final price =
                              double.tryParse(
                            priceController
                                .text
                                .trim(),
                          );

                          final category =
                              categoryController
                                  .text
                                  .trim();

                          final description =
                              descriptionController
                                  .text
                                  .trim();

                          if (name.isEmpty ||
                              price == null ||
                              category.isEmpty ||
                              description.isEmpty) {
                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill all fields correctly.',
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          final index =
                              provider.foods
                                  .indexWhere(
                            (item) =>
                                item.id ==
                                food.id,
                          );

                          if (index == -1) {
                            setDialogState(() {
                              saving = false;
                            });

                            return;
                          }

                          final success =
                              await provider.updateFood(
                            index,
                            name: name,
                            price: price,
                            description:
                                description,
                            category: category,
                          );

                          if (!context.mounted) {
                            return;
                          }

                          if (success) {
                            Navigator.pop(
                              dialogContext,
                            );

                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Food updated successfully.',
                                ),
                                backgroundColor:
                                    Colors.green,
                              ),
                            );

                            // Reload from backend.
                            await provider
                                .loadMenu();
                          } else {
                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  provider.error ??
                                      'Failed to update food.',
                                ),
                                backgroundColor:
                                    Colors.red,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    priceController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9F4),

      appBar: AppBar(
        backgroundColor:
            Colors.orange,
        foregroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'Manage Menu',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: _refreshMenu,
          ),
        ],
      ),

      body: Consumer<MenuProvider>(
        builder: (
          context,
          provider,
          child,
        ) {
          // ======================================================
          // LOADING
          // ======================================================

          if (provider.isLoading &&
              provider.foods.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (provider.error != null &&
              provider.foods.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'Failed to load menu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      provider.error!,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton.icon(
                      onPressed:
                          provider.loadMenu,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'Retry',
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange,
                        foregroundColor:
                            Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ======================================================
          // FOOD LIST
          // ======================================================

          final foods =
              provider.foods;

          if (foods.isEmpty) {
            return const Center(
              child: Text(
                'No Food Items Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: Colors.orange,
            onRefresh: _refreshMenu,

            child: ListView.builder(
              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  foods.length,

              itemBuilder:
                  (context, index) {
                final food =
                    foods[index];

                return _foodCard(
                  context,
                  provider,
                  food,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FOOD CARD
  // ============================================================

  Widget _foodCard(
    BuildContext context,
    MenuProvider provider,
    FoodModel food,
  ) {
    final bool isUpdating =
        _updatingFoodId == food.id;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),

      elevation: 3,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),

      child: Padding(
        padding:
            const EdgeInsets.all(14),

        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                Container(
                  height: 65,
                  width: 65,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.orange
                            .withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),

                  child:
                      food.imagePath.isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),

                              child:
                                  Image.asset(
                                food.imagePath,
                                fit:
                                    BoxFit.cover,

                                errorBuilder:
                                    (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Icon(
                                    Icons.fastfood,
                                    color:
                                        Colors.orange,
                                    size: 32,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.fastfood,
                              color:
                                  Colors.orange,
                              size: 32,
                            ),
                ),

                const SizedBox(
                  width: 14,
                ),

                // ==================================================
                // FOOD DETAILS
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        food.name,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        '₹${food.price.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.green,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        food.category,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        food.description,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      // ==================================================
                      // STATUS
                      // ==================================================

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              food.isAvailable
                                  ? Colors.green
                                      .shade50
                                  : Colors.red
                                      .shade50,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        child: Text(
                          food.isAvailable
                              ? 'AVAILABLE'
                              : 'UNAVAILABLE',

                          style: TextStyle(
                            color:
                                food.isAvailable
                                    ? Colors.green
                                    : Colors.red,

                            fontSize: 11,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DELETE
                // ==================================================

                IconButton(
                  icon:
                      const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),

                  onPressed:
                      isUpdating
                          ? null
                          : () {
                              _deleteFood(
                                context,
                                provider,
                                food,
                              );
                            },
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ======================================================
            // EDIT + AVAILABILITY
            // ======================================================

            Row(
              children: [
                // ==================================================
                // EDIT
                // ==================================================

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        isUpdating
                            ? null
                            : () {
                                _editFood(
                                  context,
                                  provider,
                                  food,
                                );
                              },

                    icon:
                        const Icon(
                      Icons.edit,
                      size: 18,
                    ),

                    label:
                        const Text(
                      'Edit',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                // ==================================================
                // AVAILABILITY
                // ==================================================

                Expanded(
                  child:
                      ElevatedButton.icon(
                    onPressed:
                        isUpdating
                            ? null
                            : () {
                                _toggleAvailability(
                                  context,
                                  provider,
                                  food,
                                );
                              },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          food.isAvailable
                              ? Colors.green
                              : Colors.red,

                      foregroundColor:
                          Colors.white,
                    ),

                    icon: isUpdating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : Icon(
                            food.isAvailable
                                ? Icons
                                    .check_circle
                                : Icons.cancel,
                            size: 18,
                          ),

                    label: Text(
                      isUpdating
                          ? 'Updating...'
                          : food.isAvailable
                              ? 'Available'
                              : 'Unavailable',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}