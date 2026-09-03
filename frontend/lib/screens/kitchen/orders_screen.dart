import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();

    // Load orders from SQLite/backend
    Future.microtask(() {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // ======================================================
          // LOADING
          // ======================================================

          if (orderProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            );
          }

          // ======================================================
          // ERROR
          // ======================================================

          if (orderProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),

                    const SizedBox(height: 15),

                    Text(
                      'Failed to load orders',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      orderProvider.error!,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        orderProvider.loadOrders();
                      },
                      child: const Text('RETRY'),
                    ),
                  ],
                ),
              ),
            );
          }

          final orders = orderProvider.orders;

          // ======================================================
          // NO ORDERS
          // ======================================================

          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: orderProvider.loadOrders,

              child: ListView(
                children: const [
                  SizedBox(height: 180),

                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Colors.orange,
                  ),

                  SizedBox(height: 15),

                  Center(
                    child: Text(
                      'No Orders Yet',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // ======================================================
          // ORDERS
          // ======================================================

          return RefreshIndicator(
            onRefresh: orderProvider.loadOrders,

            child: ListView.builder(
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

                                style: const TextStyle(
                                  fontSize: 19,
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
                                color: getStatusColor(
                                  order.status,
                                ).withOpacity(0.15),

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),
                              ),

                              child: Text(
                                order.status,

                                style: TextStyle(
                                  color:
                                      getStatusColor(
                                    order.status,
                                  ),

                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ==================================================
                        // TOTAL
                        // ==================================================

                        Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              color: Colors.green,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              order.total
                                  .toStringAsFixed(0),

                              style: const TextStyle(
                                fontSize: 17,
                                color: Colors.green,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

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

                        const SizedBox(height: 15),

                        // ==================================================
                        // STATUS MESSAGE
                        // ==================================================

                        Container(
                          width: double.infinity,

                          padding:
                              const EdgeInsets.all(12),

                          decoration:
                              BoxDecoration(
                            color:
                                Colors.grey.shade100,

                            borderRadius:
                                BorderRadius.circular(
                              10,
                            ),
                          ),

                          child: Text(
                            getStatusMessage(
                              order.status,
                            ),

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
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
        },
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    switch (status) {
      case 'Preparing':
        return Colors.orange;

      case 'Ready':
        return Colors.blue;

      case 'Ready for Pickup':
        return Colors.blue;

      case 'Completed':
        return Colors.green;

      case 'Confirmed':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // STATUS MESSAGE
  // ============================================================

  String getStatusMessage(String status) {
    switch (status) {
      case 'Preparing':
        return 'The canteen is preparing this order.';

      case 'Ready':
        return 'This order is ready for pickup.';

      case 'Ready for Pickup':
        return 'This order is ready for pickup.';

      case 'Completed':
        return 'This order has been collected.';

      case 'Confirmed':
        return 'Order has been confirmed.';

      default:
        return 'Order status is being updated.';
    }
  }
}