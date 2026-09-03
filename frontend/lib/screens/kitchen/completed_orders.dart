import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class CompletedOrders extends StatelessWidget {
  const CompletedOrders({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider =
        Provider.of<OrderProvider>(context);

    final orders =
        orderProvider.getOrdersByStatus("Completed");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Orders"),
        backgroundColor: Colors.orange,
      ),

      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No completed orders",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,

              itemBuilder: (context, index) {
                final OrderModel order = orders[index];

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [
                            Expanded(
                              child: Text(
                                order.foodName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color:
                                    Colors.green.shade100,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),

                              child: const Text(
                                "Completed",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "Date: ${order.date}",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "₹${order.total.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),

                            SizedBox(width: 8),

                            Text(
                              "Order collected successfully",
                              style: TextStyle(
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
                );
              },
            ),
    );
  }
}