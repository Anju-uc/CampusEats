import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isPlacingOrder = false;

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> placeOrder() async {
    final cartProvider =
        Provider.of<CartProvider>(context, listen: false);

    // ------------------------------------------------------------
    // CHECK CART
    // ------------------------------------------------------------

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your cart is empty"),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      // ==========================================================
      // CREATE ITEMS LIST
      // ==========================================================

      final List<Map<String, dynamic>> orderItems =
          cartProvider.items.map((item) {
        return {
          "name": item.name,
          "price": item.price,
          "quantity": item.quantity,
          "totalPrice": item.totalPrice,
          "cafeteria": item.cafeteria,
          "image": item.image,
        };
      }).toList();

      // ==========================================================
      // DATE
      // ==========================================================

      final String date =
          DateTime.now().toString().substring(0, 10);

      // ==========================================================
      // TOTAL
      // ==========================================================

      final double totalAmount =
          cartProvider.totalAmount;

      // ==========================================================
      // SEND COMPLETE ORDER TO BACKEND
      // ==========================================================

      final Map<String, dynamic> orderData = {
        "studentName": "Student",
        "studentEmail": "",

        // IMPORTANT:
        // Backend requires this field.
        "items": orderItems,

        // IMPORTANT:
        // Backend requires this field.
        "totalAmount": totalAmount,

        "paymentStatus": "Paid",
      };

      debugPrint("====================================");
      debugPrint("ORDER DATA");
      debugPrint(orderData.toString());
      debugPrint("====================================");

      final result =
          await ApiService.placeOrder(orderData);

      if (!mounted) return;

      // ==========================================================
      // CHECK BACKEND RESPONSE
      // ==========================================================

      if (result["success"] != true) {
        throw Exception(
          result["message"] ??
              "Failed to place order",
        );
      }

      // ==========================================================
      // ADD LOCAL ORDER
      // ==========================================================

      final orderProvider =
          Provider.of<OrderProvider>(
        context,
        listen: false,
      );

      final firstItem =
          cartProvider.items.first;

      final order = OrderModel(
        foodName: firstItem.name,
        total: totalAmount,
        date: date,
        status: "Confirmed",
      );

      orderProvider.addOrder(order);

      // ==========================================================
      // CLEAR CART
      // ==========================================================

      cartProvider.clearCart();

      // ==========================================================
      // SUCCESS MESSAGE
      // ==========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Order placed successfully!",
          ),
          backgroundColor: Colors.green,
        ),
      );

      // ==========================================================
      // GO TO SUCCESS SCREEN
      // ==========================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const OrderSuccessScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        "ORDER ERROR: $e",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to place order: $e",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final cartProvider =
        Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ==================================================
            // PAYMENT SUMMARY
            // ==================================================

            const Text(
              "Payment Summary",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // SUMMARY CARD
            // ==================================================

            Card(
              elevation: 4,

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  children: [

                    // ------------------------------------------
                    // NUMBER OF ITEMS
                    // ------------------------------------------

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [
                        const Text(
                          "Items",
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),

                        Text(
                          "${cartProvider.itemCount}",
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    const Divider(),

                    const SizedBox(height: 15),

                    // ------------------------------------------
                    // TOTAL
                    // ------------------------------------------

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        const Text(
                          "Total Amount",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        Text(
                          "₹${cartProvider.totalAmount.toStringAsFixed(0)}",

                          style:
                              const TextStyle(
                            fontSize: 22,
                            color: Colors.green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // PAYMENT METHOD
            // ==================================================

            const Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 3,

              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(12),
              ),

              child: ListTile(

                leading:
                    const CircleAvatar(
                  backgroundColor:
                      Colors.orange,

                  child: Icon(
                    Icons
                        .account_balance_wallet,
                    color: Colors.white,
                  ),
                ),

                title: const Text(
                  "CampusEats Payment",
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                subtitle: const Text(
                  "Demo payment",
                ),

                trailing:
                    const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ),

            const Spacer(),

            // ==================================================
            // PAY BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(

                onPressed:
                    _isPlacingOrder
                        ? null
                        : placeOrder,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange,

                  foregroundColor:
                      Colors.white,

                  disabledBackgroundColor:
                      Colors.orange.shade200,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child:
                    _isPlacingOrder

                        ? const SizedBox(
                            height: 25,
                            width: 25,

                            child:
                                CircularProgressIndicator(
                              color:
                                  Colors.white,
                              strokeWidth: 3,
                            ),
                          )

                        : const Text(
                            "PAY & PLACE ORDER",

                            style:
                                TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}