import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    this.order,
  });

  final OrderModel? order;

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final currentOrder =
        order ??
        (orderProvider.orders.isNotEmpty
            ? orderProvider.orders.last
            : null);

    if (currentOrder == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F2),
        appBar: AppBar(
          title: const Text(
            "Track Order",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFFF8A00),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delivery_dining,
                    size: 50,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "No active order",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Place an order to track your food here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final status = currentOrder.status;

    final isConfirmed = true;

    final isPreparing =
        status == "Preparing" ||
        status == "Ready" ||
        status == "Completed";

    final isReady =
        status == "Ready" ||
        status == "Completed";

    final isCompleted =
        status == "Completed";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "Track Your Order",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              // Provider automatically rebuilds
              // when the order status changes.
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OrderTrackingScreen(
                    order: currentOrder,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ==================================================
            // CURRENT STATUS BANNER
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9800),
                    Color(0xFFFF6D00),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(24),
              ),

              child: Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,

                    decoration: BoxDecoration(
                      color: Colors.white
                          .withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),

                    child: Icon(
                      status == "Completed"
                          ? Icons.check_circle
                          : status == "Ready"
                              ? Icons.notifications_active
                              : Icons.restaurant,
                      color: Colors.white,
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
                          "Order Status",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          status == "Preparing"
                              ? "Your food is being prepared 🍳"
                              : status == "Ready"
                                  ? "Ready for pickup! 🎉"
                                  : status ==
                                          "Completed"
                                      ? "Order completed! ❤️"
                                      : "Order confirmed! 🎉",

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // ORDER DETAILS
            // ==================================================

            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      const Text(
                        "Your Order",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const Spacer(),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.orange
                              .shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child: Text(
                          "CampusEats",
                          style:
                              TextStyle(
                            color:
                                Colors.orange
                                    .shade800,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding:
                        const EdgeInsets.all(
                      14,
                    ),

                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF8F2,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),

                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,

                          decoration:
                              BoxDecoration(
                            color: Colors
                                .orange
                                .shade100,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              13,
                            ),
                          ),

                          child:
                              const Icon(
                            Icons.restaurant,
                            color:
                                Colors.orange,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child:
                              Text(
                            currentOrder
                                .foodName,

                            style:
                                const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  detailRow(
                    Icons.currency_rupee,
                    "Total Amount",
                    "₹${currentOrder.total.toStringAsFixed(0)}",
                  ),

                  const SizedBox(height: 10),

                  detailRow(
                    Icons.calendar_today,
                    "Order Date",
                    currentOrder.date.toString(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TRACKING
            // ==================================================

            const Text(
              "Live Order Tracking",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 12,
                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),

              child: Column(
                children: [

                  trackingStep(
                    icon:
                        Icons.check_circle,
                    title:
                        "Order Confirmed",
                    subtitle:
                        "Your order has been received.",
                    active:
                        isConfirmed,
                    color:
                        Colors.green,
                  ),

                  trackingLine(
                    active:
                        isPreparing,
                  ),

                  trackingStep(
                    icon:
                        Icons.restaurant,
                    title:
                        "Preparing Food",
                    subtitle:
                        "Kitchen staff are preparing your food.",
                    active:
                        isPreparing,
                    color:
                        Colors.orange,
                  ),

                  trackingLine(
                    active:
                        isReady,
                  ),

                  trackingStep(
                    icon:
                        Icons.notifications_active,
                    title:
                        "Ready for Pickup",
                    subtitle:
                        "Your food is ready at the cafeteria.",
                    active:
                        isReady,
                    color:
                        Colors.blue,
                  ),

                  trackingLine(
                    active:
                        isCompleted,
                  ),

                  trackingStep(
                    icon:
                        Icons.check_circle,
                    title:
                        "Order Collected",
                    subtitle:
                        "Enjoy your meal! ❤️",
                    active:
                        isCompleted,
                    color:
                        Colors.green,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // CURRENT STATUS MESSAGE
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color:
                    Colors.orange.shade50,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color:
                      Colors.orange.shade200,
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
                          Colors.white,
                      shape:
                          BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.info_outline,
                      color:
                          Colors.orange,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      getStatusMessage(
                        status,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // HELP
            // ==================================================

            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.support_agent,
                ),
                label: const Text(
                  "Need help with your order?",
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.grey.shade600,
        ),

        const SizedBox(width: 10),

        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget trackingStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool active,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 300,
          ),

          height: 50,
          width: 50,

          decoration: BoxDecoration(
            color: active
                ? color
                : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),

          child: Icon(
            icon,
            color: active
                ? Colors.white
                : Colors.grey.shade400,
            size: 25,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(
              top: 3,
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color: active
                        ? Colors.black
                        : Colors.grey,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: active
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget trackingLine({
    required bool active,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(
        left: 24,
      ),

      height: 38,
      width: 3,

      decoration: BoxDecoration(
        color: active
            ? Colors.green
            : Colors.grey.shade300,
        borderRadius:
            BorderRadius.circular(5),
      ),
    );
  }

  String getStatusMessage(
    String status,
  ) {
    switch (status) {
      case "Preparing":
        return "Your food is currently being prepared by the kitchen team.";

      case "Ready":
        return "Your food is ready! Please collect it from your cafeteria counter.";

      case "Completed":
        return "Your order has been collected. Enjoy your meal! ❤️";

      default:
        return "Your order has been confirmed and will be prepared soon.";
    }
  }
}