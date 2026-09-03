import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class FoodDetailsScreen extends StatefulWidget {
  final String name;
  final String price;
  final IconData icon;

  // Optional cafeteria.
  // Existing calls using only name, price and icon will still work.
  final String cafeteria;

  const FoodDetailsScreen({
    super.key,
    required this.name,
    required this.price,
    required this.icon,
    this.cafeteria = 'Main Cafeteria',
  });

  @override
  State<FoodDetailsScreen> createState() =>
      _FoodDetailsScreenState();
}

class _FoodDetailsScreenState
    extends State<FoodDetailsScreen> {
  int quantity = 1;

  // ============================================================
  // GET NUMERIC PRICE
  // ============================================================

  double get numericPrice {
    final cleanedPrice = widget.price
        .replaceAll('₹', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleanedPrice) ?? 0;
  }

  // ============================================================
  // TOTAL PRICE
  // ============================================================

  double get totalPrice {
    return numericPrice * quantity;
  }

  // ============================================================
  // INCREASE QUANTITY
  // ============================================================

  void increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  // ============================================================
  // DECREASE QUANTITY
  // ============================================================

  void decreaseQuantity() {
    if (quantity <= 1) {
      return;
    }

    setState(() {
      quantity--;
    });
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  void addToCart() {
    final cartProvider =
        context.read<CartProvider>();

    // ----------------------------------------------------------
    // CREATE CART ITEM
    // ----------------------------------------------------------

    final item = CartItem(
      name: widget.name,
      price: numericPrice,
      quantity: quantity,
      cafeteria: widget.cafeteria,
      image: '',
    );

    // ----------------------------------------------------------
    // ADD ITEM
    //
    // IMPORTANT:
    // CartProvider.addItem() returns VOID.
    //
    // So DO NOT do:
    //
    // final success = cartProvider.addItem(item);
    //
    // and DO NOT do:
    //
    // if (!success)
    //
    // ----------------------------------------------------------

    cartProvider.addItem(item);

    // ----------------------------------------------------------
    // SHOW SUCCESS MESSAGE
    // ----------------------------------------------------------

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.name} added to cart',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CartScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // OPEN CART
  // ============================================================

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CartScreen(),
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
          const Color(0xFFFFF8F1),

      // ==========================================================
      // APP BAR
      // ==========================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Food Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: openCart,
            icon: const Icon(
              Icons.shopping_cart_outlined,
            ),
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // FOOD IMAGE / ICON
            // ======================================================

            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8D0),
              ),
              child: Center(
                child: Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset:
                            Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 85,
                    color:
                        const Color(0xFFFF8A00),
                  ),
                ),
              ),
            ),

            // ======================================================
            // CONTENT
            // ======================================================

            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // FOOD NAME
                  // ==================================================

                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // RATING
                  // ==================================================

                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors.green
                              .shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons
                                  .star_rounded,
                              size: 18,
                              color:
                                  Colors.orange,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Text(
                              '4.8',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Text(
                        widget.cafeteria,
                        style: TextStyle(
                          color: Colors
                              .grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // PRICE
                  // ==================================================

                  Text(
                    widget.price,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // DESCRIPTION
                  // ==================================================

                  const Text(
                    'About this food',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'Freshly prepared food available '
                    'from the campus cafeteria. '
                    'Order now and enjoy your meal '
                    'without waiting in line.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color:
                          Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // CAFETERIA
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      15,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.orange.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.orange,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Text(
                                'Cafeteria',
                                style:
                                    TextStyle(
                                  fontSize: 12,
                                  color: Colors
                                      .grey,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                widget.cafeteria,
                                style:
                                    const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // QUANTITY
                  // ==================================================

                  const Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                      border: Border.all(
                        color: Colors
                            .grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        // MINUS

                        IconButton(
                          onPressed:
                              decreaseQuantity,
                          icon: const Icon(
                            Icons
                                .remove_circle_outline,
                          ),
                          color:
                              Colors.orange,
                        ),

                        Container(
                          width: 45,
                          alignment:
                              Alignment
                                  .center,
                          child: Text(
                            '$quantity',
                            style:
                                const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),

                        // PLUS

                        IconButton(
                          onPressed:
                              increaseQuantity,
                          icon: const Icon(
                            Icons
                                .add_circle_outline,
                          ),
                          color:
                              Colors.orange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 25,
                  ),

                  // ==================================================
                  // TOTAL
                  // ==================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color:
                              Colors.black12,
                          blurRadius: 8,
                          offset:
                              Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style:
                              TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        Text(
                          '₹${totalPrice.toStringAsFixed(0)}',
                          style:
                              const TextStyle(
                            color:
                                Colors.green,
                            fontSize: 23,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // ADD TO CART BUTTON
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          addToCart,

                      icon: const Icon(
                        Icons
                            .shopping_cart_outlined,
                      ),

                      label: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFFF8A00,
                        ),
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // BUY NOW
                  // ==================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child:
                        OutlinedButton(
                      onPressed: () {
                        addToCart();
                        openCart();
                      },

                      style:
                          OutlinedButton
                              .styleFrom(
                        foregroundColor:
                            Colors.orange,
                        side:
                            const BorderSide(
                          color:
                              Colors.orange,
                          width: 1.5,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),
                      ),

                      child: const Text(
                        'BUY NOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}