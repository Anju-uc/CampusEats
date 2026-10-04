import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/order_rating_dialog.dart';
import 'order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final Map<String, Map<String, dynamic>> _userReviews = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(studentOnly: true);
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await ApiService.fetchMyReviews();
      if (mounted) {
        setState(() {
          for (final rev in reviews) {
            final oId = rev['orderId']?.toString();
            if (oId != null && oId.isNotEmpty) {
              _userReviews[oId] = rev;
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final orders = orderProvider.orders;

    Widget body;
    if (orderProvider.isLoading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (orderProvider.error != null && orders.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 12),
              Text(orderProvider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => orderProvider.loadOrders(studentOnly: true),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    } else if (orders.isEmpty) {
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 15),
            Text(
              "No Orders Yet",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Your orders will appear here.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(context, orders[index]);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.orange,
      ),
      body: body,
    );
  }

  String _formatIsoTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return iso;
    }
  }

  String _formatIsoWindow(String? startIso, String? endIso) {
    if (startIso == null || startIso.isEmpty) return '';
    final startStr = _formatIsoTime(startIso);
    if (endIso == null || endIso.isEmpty) {
      try {
        final startDt = DateTime.parse(startIso).toLocal();
        final endDt = startDt.add(const Duration(minutes: 15));
        final endHour = endDt.hour % 12 == 0 ? 12 : endDt.hour % 12;
        final endMinute = endDt.minute.toString().padLeft(2, '0');
        final endPeriod = endDt.hour >= 12 ? 'PM' : 'AM';
        return '$startStr – $endHour:$endMinute $endPeriod';
      } catch (_) {
        return startStr;
      }
    }
    return '$startStr – ${_formatIsoTime(endIso)}';
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> orderData) {
    final order = OrderModel.fromMap(orderData);
    final isScheduled = order.isScheduled;
    final isNoShow = order.pickupStatus == 'NO_SHOW' || order.status == 'NO_SHOW';
    final isReady = order.status == 'Ready' || order.pickupStatus == 'READY';
    final orderIdStr = order.id?.toString() ?? '';
    final reviewData = _userReviews[orderIdStr];
    final bool isReviewed = reviewData != null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: isScheduled ? Colors.deepOrange : Colors.orange,
                  child: Icon(
                    isScheduled ? Icons.access_time_rounded : Icons.restaurant,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.foodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (isScheduled) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "SCHEDULED",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "₹${order.total.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(Items: ₹${order.subtotal.toStringAsFixed(0)} + GST: ₹${order.gst.toStringAsFixed(0)})",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isScheduled && order.scheduledPickupAt != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(
                          "Pickup: ${_formatIsoTime(order.scheduledPickupAt)}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Pickup Window: ${_formatIsoWindow(order.scheduledPickupAt, order.pickupWindowEndAt)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status:",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isNoShow ? Colors.red : getStatusColor(order.status)).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isNoShow ? 'No Show' : order.status,
                    style: TextStyle(
                      color: isNoShow ? Colors.red : getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            if (isReady) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Your order is ready for pickup.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isNoShow) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Pickup window expired.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // BUTTON ROW: TRACK ORDER + RATING (FEATURE 2)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(order: order),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on, size: 16),
                    label: const Text("TRACK ORDER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                if (order.canBeRated && orderIdStr.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  if (isReviewed)
                    OutlinedButton.icon(
                      onPressed: () {
                        ViewOrderReviewDialog.show(
                          context,
                          rating: int.tryParse(reviewData['rating']?.toString() ?? '5') ?? 5,
                          review: reviewData['review']?.toString() ?? '',
                          foodName: order.foodName,
                          cafeteria: order.cafeteria,
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                      label: const Text(
                        "Reviewed ✓",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        OrderRatingDialog.show(
                          context,
                          orderId: orderIdStr,
                          foodName: order.foodName,
                          cafeteria: order.cafeteria,
                          onReviewSubmitted: (rating, rev) {
                            setState(() {
                              _userReviews[orderIdStr] = {
                                'orderId': orderIdStr,
                                'rating': rating,
                                'review': rev,
                              };
                            });
                          },
                        );
                      },
                      icon: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                      label: const Text("Rate Order"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ],
        ),
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
      case "NO_SHOW":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
