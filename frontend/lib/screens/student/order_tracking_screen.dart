import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../widgets/order_rating_dialog.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, this.order});

  final OrderModel? order;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _existingReview;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkExistingReview();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollOrders();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _pollOrders();
      }
    });
  }

  void _pollOrders() {
    final targetId = widget.order?.id?.toString();
    context.read<OrderProvider>().loadOrders();
    if (targetId != null && targetId.isNotEmpty) {
      _checkExistingReview(targetId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkExistingReview([String? targetOrderId]) async {
    final orderId = targetOrderId ?? widget.order?.id?.toString();
    if (orderId == null || orderId.isEmpty) return;

    try {
      final review = await ApiService.fetchOrderReview(orderId);
      if (mounted) {
        setState(() {
          _existingReview = review;
        });
      }
    } catch (_) {}
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

  String _getDisplayStatus(String status, {bool isNoShow = false, bool isReleased = false, bool isCollected = false}) {
    if (isNoShow) return "No Show";
    if (isReleased) return "Released";
    if (isCollected) return "Order Collected";
    final upper = status.trim().toUpperCase();
    if (upper == 'PREPARING') return "Preparing Food";
    if (upper == 'READY') return "Ready for Pickup";
    if (upper == 'COMPLETED' || upper == 'COLLECTED') return "Order Collected";
    return "Order Confirmed";
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    final targetId = widget.order?.id?.toString();
    OrderModel? currentOrder;
    if (targetId != null && targetId.isNotEmpty) {
      final match = orderProvider.orders.cast<Map<String, dynamic>?>().firstWhere(
        (o) => o != null && (
          orderProvider.getOrderId(o) == targetId ||
          o['_id']?.toString() == targetId ||
          o['id']?.toString() == targetId ||
          o['orderId']?.toString() == targetId
        ),
        orElse: () => null,
      );
      if (match != null) {
        currentOrder = OrderModel.fromMap(match);
      }
    }

    currentOrder ??= (orderProvider.orders.isNotEmpty
        ? OrderModel.fromMap(orderProvider.orders.first)
        : widget.order);

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
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Place an order to track your food here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final OrderModel resolvedOrder = currentOrder;
    final status = resolvedOrder.status;
    final upperStatus = status.trim().toUpperCase();
    final isScheduled = resolvedOrder.isScheduled;
    final isNoShow = resolvedOrder.pickupStatus == 'NO_SHOW' || upperStatus == 'NO_SHOW';
    final isReleased = resolvedOrder.pickupStatus == 'RELEASED' || upperStatus == 'RELEASED';

    const isConfirmed = true;
    final isPreparing = upperStatus == "PREPARING" || upperStatus == "READY" || upperStatus == "COMPLETED" || upperStatus == "COLLECTED";
    final isReady = upperStatus == "READY" || upperStatus == "COMPLETED" || upperStatus == "COLLECTED";
    final isCompleted = resolvedOrder.isCollected || upperStatus == "COMPLETED" || upperStatus == "COLLECTED";
    final orderIdStr = resolvedOrder.id?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8A00),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Track Your Order",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<OrderProvider>().loadOrders();
              await _checkExistingReview(orderIdStr);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () async {
          await context.read<OrderProvider>().loadOrders();
          await _checkExistingReview(orderIdStr);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  gradient: LinearGradient(
                    colors: isNoShow || isReleased
                        ? [Colors.red.shade700, Colors.red.shade900]
                        : const [Color(0xFFFF9800), Color(0xFFFF6D00)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNoShow || isReleased
                            ? Icons.warning_amber_rounded
                            : isCompleted
                                ? Icons.check_circle
                                : isReady
                                    ? Icons.notifications_active
                                    : Icons.restaurant,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isScheduled ? "Scheduled Order Status" : "Order Status",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getDisplayStatus(
                              status,
                              isNoShow: isNoShow,
                              isReleased: isReleased,
                              isCollected: isCompleted,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

            // ==================================================
            // RATING & REVIEW CARD (FEATURE 2 - AFTER COLLECTION ONLY)
            // ==================================================
            if (resolvedOrder.canBeRated && orderIdStr.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _existingReview != null
                        ? Colors.green.shade300
                        : Colors.amber.shade300,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_existingReview != null ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _existingReview != null
                              ? Icons.check_circle_rounded
                              : Icons.star_rate_rounded,
                          color: _existingReview != null ? Colors.green : Colors.amber.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _existingReview != null
                              ? "Thank you for your feedback!"
                              : "Rate your order",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _existingReview != null ? Colors.green.shade900 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _existingReview != null
                          ? "You gave this order ${_existingReview!['rating'] ?? 5} stars."
                          : "How was your food and pickup experience at ${resolvedOrder.cafeteria}?",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    if (_existingReview != null) ...[
                      Row(
                        children: [
                          Row(
                            children: List.generate(
                              int.tryParse(_existingReview!['rating']?.toString() ?? '5') ?? 5,
                              (i) => const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () {
                              ViewOrderReviewDialog.show(
                                context,
                                rating: int.tryParse(
                                        _existingReview!['rating']?.toString() ?? '5') ??
                                    5,
                                review: _existingReview!['review']?.toString() ?? '',
                                foodName: resolvedOrder.foodName,
                                cafeteria: resolvedOrder.cafeteria,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Reviewed ✓",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            OrderRatingDialog.show(
                              context,
                              orderId: orderIdStr,
                              foodName: resolvedOrder.foodName,
                              cafeteria: resolvedOrder.cafeteria,
                              onReviewSubmitted: (rating, rev) {
                                setState(() {
                                  _existingReview = {
                                    'orderId': orderIdStr,
                                    'rating': rating,
                                    'review': rev,
                                  };
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.star_rounded, size: 18),
                          label: const Text(
                            "Rate Your Order ★★★★★",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ==================================================
            // ORDER DETAILS & BILL BREAKDOWN (FEATURE 1)
            // ==================================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Your Order",
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isScheduled ? Colors.orange.shade100 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isScheduled ? "SCHEDULED" : "ASAP",
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resolvedOrder.foodName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                resolvedOrder.cafeteria,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  detailRow(
                    Icons.shopping_bag_outlined,
                    "Item Total",
                    "₹${resolvedOrder.subtotal.toStringAsFixed(0)}",
                  ),
                  const SizedBox(height: 8),
                  detailRow(
                    Icons.store_mall_directory_outlined,
                    "Cafeteria Pickup Fee",
                    "FREE / ₹0",
                  ),
                  const SizedBox(height: 8),
                  detailRow(
                    Icons.receipt_outlined,
                    "GST",
                    "₹${resolvedOrder.gst.toStringAsFixed(0)}",
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  detailRow(
                    Icons.currency_rupee,
                    "Total Paid",
                    "₹${resolvedOrder.total.toStringAsFixed(0)}",
                    isBold: true,
                  ),

                  const SizedBox(height: 10),
                  detailRow(
                    Icons.calendar_today,
                    "Order Date",
                    resolvedOrder.date.toString(),
                  ),

                  if (isScheduled && resolvedOrder.scheduledPickupAt != null) ...[
                    const SizedBox(height: 10),
                    detailRow(
                      Icons.schedule,
                      "Scheduled Pickup",
                      _formatIsoTime(resolvedOrder.scheduledPickupAt),
                    ),
                    const SizedBox(height: 10),
                    detailRow(
                      Icons.timelapse,
                      "Pickup Window",
                      _formatIsoWindow(
                        resolvedOrder.scheduledPickupAt,
                        resolvedOrder.pickupWindowEndAt,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TRACKING STEPS
            // ==================================================
            const Text(
              "Live Order Tracking",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  trackingStep(
                    icon: Icons.check_circle,
                    title: "Order Confirmed",
                    subtitle: "Your order has been received.",
                    active: isConfirmed,
                    color: Colors.green,
                  ),
                  trackingLine(active: isPreparing),
                  trackingStep(
                    icon: Icons.restaurant,
                    title: "Preparing Food",
                    subtitle: "Kitchen staff are preparing your food.",
                    active: isPreparing,
                    color: Colors.orange,
                  ),
                  trackingLine(active: isReady),
                  trackingStep(
                    icon: Icons.notifications_active,
                    title: "Ready for Pickup",
                    subtitle: "Your food is ready at the cafeteria.",
                    active: isReady,
                    color: Colors.blue,
                  ),
                  trackingLine(active: isCompleted),
                  trackingStep(
                    icon: Icons.check_circle,
                    title: "Order Collected",
                    subtitle: "Enjoy your meal! ❤️",
                    active: isCompleted,
                    color: Colors.green,
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      getStatusMessage(status),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent),
                label: const Text("Need help with your order?"),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

  Widget detailRow(IconData icon, String title, String value, {bool isBold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: isBold ? Colors.black87 : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isBold ? 15 : 13,
              color: isBold ? Colors.green.shade800 : Colors.black87,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: active ? color : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : Colors.grey.shade400,
            size: 25,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: active ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget trackingLine({required bool active}) {
    return Container(
      margin: const EdgeInsets.only(left: 24),
      height: 38,
      width: 3,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  String getStatusMessage(String status) {
    final upper = status.trim().toUpperCase();
    switch (upper) {
      case "PREPARING":
        return "Your food is currently being prepared by the kitchen team.";
      case "READY":
        return "Your food is ready! Please collect it from your cafeteria counter.";
      case "COMPLETED":
      case "COLLECTED":
        return "Your order has been collected. Enjoy your meal! ❤️";
      case "NO_SHOW":
        return "Order was not collected within the pickup window.";
      case "RELEASED":
        return "Uncollected food has been released.";
      default:
        return "Your order has been confirmed and will be prepared soon.";
    }
  }
}
