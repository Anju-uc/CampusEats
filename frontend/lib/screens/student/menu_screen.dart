import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/food_model.dart';
import '../../models/cart_item.dart';
import '../../providers/menu_provider.dart';
import '../../providers/cart_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final TextEditingController searchController =
      TextEditingController();

  String selectedCategory = 'All';
  String selectedCafeteria = 'Main Cafeteria';

  final List<String> categories = [
    'All',
    'South Indian',
    'North Indian',
    'Chinese',
    'Non Veg',
    'Fast Food',
    'Beverages',
  ];

  final List<String> cafeterias = [
    'Main Cafeteria',
    'Block A',
    'Block B',
    'Block C',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MenuProvider>().loadMenu();
      }
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTER FOODS
  // ============================================================

  List<FoodModel> getFilteredFoods(
    List<FoodModel> foods,
  ) {
    final search =
        searchController.text.trim().toLowerCase();

    return foods.where((food) {
      // CATEGORY
      final matchesCategory =
          selectedCategory == 'All' ||
          food.category.toLowerCase() ==
              selectedCategory.toLowerCase();

      // SEARCH
      final matchesSearch =
          search.isEmpty ||
          food.name.toLowerCase().contains(search) ||
          food.description.toLowerCase().contains(search);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  void addToCart(
    BuildContext context,
    FoodModel food,
  ) {
    // ----------------------------------------------------------
    // DO NOT ADD UNAVAILABLE FOOD
    // ----------------------------------------------------------

    if (!food.isAvailable) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This food is currently unavailable.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CREATE CART ITEM
    // ----------------------------------------------------------

    final cartProvider =
        context.read<CartProvider>();

    final item = CartItem(
      name: food.name,
      price: food.price,
      quantity: 1,
      cafeteria: selectedCafeteria,
      image: food.imagePath,
    );

    // ----------------------------------------------------------
    // ADD ITEM
    //
    // IMPORTANT:
    // No bool result.
    // No cafeteria restriction.
    // Items from different cafeterias are allowed.
    // ----------------------------------------------------------

    cartProvider.addItem(item);

    // ----------------------------------------------------------
    // SUCCESS MESSAGE
    // ----------------------------------------------------------

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${food.name} added to cart',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // SHOW FOOD DETAILS
  // ============================================================

  void showFoodDetails(
    BuildContext context,
    FoodModel food,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF9F4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // IMAGE
                  // ==================================================

                  Center(
                    child: food.imagePath.isNotEmpty &&
                            food.imagePath.startsWith('http')
                        ? ClipRRect(
                            borderRadius:
                                BorderRadius.circular(18),
                            child: Image.network(
                              food.imagePath,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return foodPlaceholder(
                                  width: double.infinity,
                                  height: 180,
                                );
                              },
                            ),
                          )
                        : foodPlaceholder(
                            width: double.infinity,
                            height: 180,
                          ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // NAME
                  // ==================================================

                  Text(
                    food.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // CATEGORY
                  // ==================================================

                  Text(
                    food.category,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // PRICE
                  // ==================================================

                  Text(
                    '₹${food.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  Text(
                    food.description.isEmpty
                        ? 'No description available.'
                        : food.description,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // CAFETERIA
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
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
                            selectedCafeteria,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // AVAILABILITY
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: food.isAvailable
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      food.isAvailable
                          ? 'Available'
                          : 'Currently Unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: food.isAvailable
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ==================================================
                  // ADD TO CART
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: food.isAvailable
                          ? () {
                              Navigator.pop(context);

                              addToCart(
                                context,
                                food,
                              );
                            }
                          : null,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange,
                        foregroundColor:
                            Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade300,
                        disabledForegroundColor:
                            Colors.grey.shade600,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        food.isAvailable
                            ? 'ADD TO CART'
                            : 'UNAVAILABLE',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FOOD CARD
  // ============================================================

  Widget foodCard(
    BuildContext context,
    FoodModel food,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          showFoodDetails(
            context,
            food,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ==================================================
              // IMAGE
              // ==================================================

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(14),
                child: food.imagePath.isNotEmpty &&
                        food.imagePath.startsWith('http')
                    ? Image.network(
                        food.imagePath,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return foodPlaceholder();
                        },
                      )
                    : foodPlaceholder(),
              ),

              const SizedBox(width: 14),

              // ==================================================
              // FOOD INFORMATION
              // ==================================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      food.category,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      '₹${food.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // AVAILABILITY LABEL
                    // ==================================================

                    if (!food.isAvailable)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.red.shade50,
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: const Text(
                          'UNAVAILABLE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // ADD BUTTON
              // ==================================================

              SizedBox(
                width: 70,
                child: ElevatedButton(
                  onPressed: food.isAvailable
                      ? () {
                          addToCart(
                            context,
                            food,
                          );
                        }
                      : null,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orange,
                    foregroundColor:
                        Colors.white,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    disabledForegroundColor:
                        Colors.grey.shade600,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    food.isAvailable
                        ? 'ADD'
                        : 'OFF',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PLACEHOLDER
  // ============================================================

  Widget foodPlaceholder({
    double width = 100,
    double height = 100,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.orange.shade100,
      child: const Icon(
        Icons.fastfood,
        size: 45,
        color: Colors.orange,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF9F4),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        title: const Text(
          'CampusEats Menu',
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: () async {
              await context
                  .read<MenuProvider>()
                  .loadMenu();
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: Consumer<MenuProvider>(
        builder: (
          context,
          menuProvider,
          child,
        ) {
          // ========================================================
          // LOADING
          // ========================================================

          if (menuProvider.isLoading &&
              menuProvider.foods.isEmpty) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          // ========================================================
          // ERROR
          // ========================================================

          if (menuProvider.error != null &&
              menuProvider.foods.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 70,
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
                      menuProvider.error!,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ElevatedButton(
                      onPressed: () {
                        menuProvider
                            .loadMenu();
                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange,
                        foregroundColor:
                            Colors.white,
                      ),
                      child:
                          const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ========================================================
          // FILTERED FOOD
          // ========================================================

          final foods =
              getFilteredFoods(
            menuProvider.foods,
          );

          // ========================================================
          // MAIN CONTENT
          // ========================================================

          return RefreshIndicator(
            color: Colors.orange,

            onRefresh:
                menuProvider.loadMenu,

            child:
                SingleChildScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding:
                  const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // CAFETERIA
                  // ==================================================

                  const Text(
                    'Select Cafeteria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  DropdownButtonFormField<
                      String>(
                    value:
                        selectedCafeteria,

                    decoration:
                        InputDecoration(
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                      prefixIcon:
                          const Icon(
                        Icons.restaurant,
                        color: Colors.orange,
                      ),
                    ),

                    items: cafeterias
                        .map(
                          (
                            cafeteria,
                          ) {
                            return DropdownMenuItem<
                                String>(
                              value:
                                  cafeteria,
                              child: Text(
                                cafeteria,
                              ),
                            );
                          },
                        )
                        .toList(),

                    onChanged:
                        (value) {
                      if (value != null) {
                        setState(() {
                          selectedCafeteria =
                              value;
                        });
                      }
                    },
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // SEARCH
                  // ==================================================

                  TextField(
                    controller:
                        searchController,

                    onChanged: (_) {
                      setState(() {});
                    },

                    decoration:
                        InputDecoration(
                      hintText:
                          'Search food...',

                      prefixIcon:
                          const Icon(
                        Icons.search,
                      ),

                      suffixIcon:
                          searchController
                                  .text
                                  .isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(
                                    Icons.clear,
                                  ),
                                  onPressed:
                                      () {
                                    searchController
                                        .clear();

                                    setState(
                                      () {},
                                    );
                                  },
                                )
                              : null,

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // CATEGORIES
                  // ==================================================

                  SizedBox(
                    height: 45,

                    child:
                        ListView.separated(
                      scrollDirection:
                          Axis.horizontal,

                      itemCount:
                          categories.length,

                      separatorBuilder:
                          (
                        context,
                        index,
                      ) {
                        return const SizedBox(
                          width: 8,
                        );
                      },

                      itemBuilder:
                          (
                        context,
                        index,
                      ) {
                        final category =
                            categories[
                                index];

                        final selected =
                            selectedCategory ==
                                category;

                        return ChoiceChip(
                          label:
                              Text(category),

                          selected:
                              selected,

                          selectedColor:
                              Colors.orange,

                          checkmarkColor:
                              Colors.white,

                          labelStyle:
                              TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black,
                            fontWeight:
                                selected
                                    ? FontWeight.bold
                                    : FontWeight
                                        .normal,
                          ),

                          onSelected:
                              (_) {
                            setState(() {
                              selectedCategory =
                                  category;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // FOOD LIST
                  // ==================================================

                  if (foods.isEmpty)
                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        40,
                      ),

                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .restaurant_menu,
                            size: 70,
                            color:
                                Colors.grey,
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          const Text(
                            'No food found',
                            style:
                                TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            'Try another category or search.',
                            style: TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...foods.map(
                      (food) {
                        return foodCard(
                          context,
                          food,
                        );
                      },
                    ),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}