import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider =
        Provider.of<OrderProvider>(context);

    final orders = orderProvider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.orange,
      ),

      body: orders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    "No Orders Yet",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    "Your orders will appear here.",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )

          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,

              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  elevation: 4,

                  margin: const EdgeInsets.only(
                    bottom: 15,
                  ),

                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),

                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const CircleAvatar(
                            backgroundColor:
                                Colors.orange,

                            child: Icon(
                              Icons.restaurant,
                              color: Colors.white,
                            ),
                          ),

                          title: Text(
                            order.foodName,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                "₹${order.total.toStringAsFixed(0)}",
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.green,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                "Date: ${order.date}",
                              ),

                              const SizedBox(
                                height: 8,
                              ),

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
                                      getStatusColor(
                                    order.status,
                                  ).withOpacity(
                                    0.12,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),
                                ),

                                child: Text(
                                  order.status,
                                  style:
                                      TextStyle(
                                    color:
                                        getStatusColor(
                                      order.status,
                                    ),
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        SizedBox(
                          width:
                              double.infinity,

                          child:
                              ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          OrderTrackingScreen(
                                    order: order,
                                  ),
                                ),
                              );
                            },

                            icon: const Icon(
                              Icons
                                  .location_on,
                            ),

                            label: const Text(
                              "TRACK ORDER",
                            ),

                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  Colors.orange,

                              foregroundColor:
                                  Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Preparing":
        return Colors.orange;

      case "Ready":
        return Colors.blue;

      case "Completed":
        return Colors.green;

      default:
        return Colors.grey;
    }
  }
}