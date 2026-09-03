import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final orders = orderProvider.orders;

    final totalOrders = orders.length;

    final preparingOrders = orders
        .where((order) => order.status == "Preparing")
        .length;

    final readyOrders = orders
        .where((order) => order.status == "Ready for Pickup")
        .length;

    final completedOrders = orders
        .where((order) => order.status == "Completed")
        .length;

    double totalRevenue = 0;

    for (final order in orders) {
      totalRevenue += order.total;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports"),
        backgroundColor: Colors.orange,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            reportCard(
              icon: Icons.receipt_long,
              title: "Total Orders",
              value: totalOrders.toString(),
              color: Colors.blue,
            ),

            const SizedBox(height: 15),

            reportCard(
              icon: Icons.restaurant,
              title: "Preparing Orders",
              value: preparingOrders.toString(),
              color: Colors.orange,
            ),

            const SizedBox(height: 15),

            reportCard(
              icon: Icons.notifications_active,
              title: "Ready for Pickup",
              value: readyOrders.toString(),
              color: Colors.purple,
            ),

            const SizedBox(height: 15),

            reportCard(
              icon: Icons.check_circle,
              title: "Completed Orders",
              value: completedOrders.toString(),
              color: Colors.green,
            ),

            const SizedBox(height: 15),

            reportCard(
              icon: Icons.currency_rupee,
              title: "Total Revenue",
              value: "₹${totalRevenue.toStringAsFixed(0)}",
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget reportCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),

              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
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
}