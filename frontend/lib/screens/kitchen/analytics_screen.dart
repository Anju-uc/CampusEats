import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final orders = orderProvider.orders;

    // Total orders
    final int totalOrders = orders.length;

    // Total revenue
    double totalRevenue = 0;

    for (var order in orders) {
      totalRevenue += order.total;
    }

    // Order status counts
    int preparing = 0;
    int ready = 0;
    int completed = 0;
    int confirmed = 0;

    for (var order in orders) {
      switch (order.status) {
        case "Preparing":
          preparing++;
          break;

        case "Ready":
          ready++;
          break;

        case "Completed":
          completed++;
          break;

        default:
          confirmed++;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F4),

      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Analytics",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==========================
            // HEADER
            // ==========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.indigo,
                    Colors.deepPurple,
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(22),
              ),

              child: const Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 40,
                  ),

                  SizedBox(height: 12),

                  Text(
                    "CampusEats Analytics",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Track your orders and revenue",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==========================
            // OVERVIEW
            // ==========================

            const Text(
              "Overview",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,

              crossAxisSpacing: 14,
              mainAxisSpacing: 14,

              shrinkWrap: true,

              physics:
                  const NeverScrollableScrollPhysics(),

              childAspectRatio: 1.15,

              children: [

                _statCard(
                  icon: Icons.receipt_long,
                  title: "Total Orders",
                  value: "$totalOrders",
                  color: Colors.blue,
                ),

                _statCard(
                  icon: Icons.currency_rupee,
                  title: "Total Revenue",
                  value:
                      "₹${totalRevenue.toStringAsFixed(0)}",
                  color: Colors.green,
                ),

                _statCard(
                  icon: Icons.restaurant,
                  title: "Preparing",
                  value: "$preparing",
                  color: Colors.orange,
                ),

                _statCard(
                  icon: Icons.notifications_active,
                  title: "Ready",
                  value: "$ready",
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================
            // ORDER STATUS
            // ==========================

            const Text(
              "Order Status",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            _statusTile(
              icon: Icons.check_circle_outline,
              title: "Confirmed Orders",
              value: confirmed,
              color: Colors.blue,
            ),

            const SizedBox(height: 10),

            _statusTile(
              icon: Icons.restaurant,
              title: "Preparing Orders",
              value: preparing,
              color: Colors.orange,
            ),

            const SizedBox(height: 10),

            _statusTile(
              icon: Icons.notifications_active,
              title: "Ready Orders",
              value: ready,
              color: Colors.purple,
            ),

            const SizedBox(height: 10),

            _statusTile(
              icon: Icons.check_circle,
              title: "Completed Orders",
              value: completed,
              color: Colors.green,
            ),

            const SizedBox(height: 28),

            // ==========================
            // COMPLETED
            // ==========================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(20),

                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),

              child: Row(
                children: [

                  Container(
                    height: 55,
                    width: 55,

                    decoration: BoxDecoration(
                      color:
                          Colors.green.withOpacity(0.12),

                      borderRadius:
                          BorderRadius.circular(15),
                    ),

                    child: const Icon(
                      Icons.done_all,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Completed Orders",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "$completed orders successfully completed",
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    "$completed",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==========================
            // NOTE
            // ==========================

            Container(
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.orange.shade50,

                borderRadius:
                    BorderRadius.circular(15),

                border: Border.all(
                  color: Colors.orange.shade100,
                ),
              ),

              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "Analytics are calculated from the orders currently stored in the OrderProvider.",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // STAT CARD
  // ====================================

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(
            height: 45,
            width: 45,

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ====================================
  // STATUS TILE
  // ====================================

  Widget _statusTile({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(17),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [

          Container(
            height: 45,
            width: 45,

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),

              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Text(
            "$value",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}