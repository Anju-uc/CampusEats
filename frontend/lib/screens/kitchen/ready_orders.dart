import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class ReadyOrders extends StatelessWidget {
  const ReadyOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ready for Pickup'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          final orders =
              orderProvider.getOrdersByStatus('Ready');

          // ======================================================
          // NO ORDERS
          // ======================================================

          if (orders.isEmpty) {
            return const Center(
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
                    'No orders waiting for pickup',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          // ======================================================
          // READY ORDERS
          // ======================================================

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: orders.length,

            itemBuilder: (context, index) {
              final OrderModel order = orders[index];

              final actualIndex =
                  orderProvider.orders.indexOf(order);

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
                      // ==================================================
                      // FOOD + STATUS
                      // ==================================================

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,

                        children: [
                          Expanded(
                            child: Text(
                              order.foodName,

                              style:
                                  const TextStyle(
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

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.blue.shade100,

                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: const Text(
                              'Ready',

                              style:
                                  TextStyle(
                                color:
                                    Colors.blue,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ==================================================
                      // DATE
                      // ==================================================

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 8),

                          Text(
                            order.date,

                            style:
                                const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // TOTAL
                      // ==================================================

                      Text(
                        '₹${order.total.toStringAsFixed(0)}',

                        style:
                            const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ==================================================
                      // COLLECTED
                      // ==================================================

                      SizedBox(
                        width: double.infinity,

                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (actualIndex == -1) {
                              return;
                            }

                            final success =
                                await orderProvider
                                    .markCollected(
                              actualIndex,
                            );

                            if (!context.mounted) {
                              return;
                            }

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Order completed successfully!'
                                      : 'Failed to update order.',
                                ),

                                backgroundColor:
                                    success
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            );
                          },

                          icon: const Icon(
                            Icons.check_circle,
                          ),

                          label: const Text(
                            'COLLECTED',
                          ),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.green,

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}