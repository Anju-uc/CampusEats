import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
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

  @override
  void initState() {
    super.initState();

    // Load orders from SQLite/backend
    Future.microtask(() async {
      await ApiService.restoreAdminSession();
      await ApiService.restoreKitchenSession();
      if (!mounted) return;
      await context.read<OrderProvider>().loadOrders();
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
              child: CircularProgressIndicator(color: Colors.orange),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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

                    Text(orderProvider.error!, textAlign: TextAlign.center),

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

                  Icon(Icons.receipt_long, size: 80, color: Colors.orange),

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
                final orderMap = orders[index];
                final order = OrderModel.fromMap(orderMap);
                final isScheduled = order.isScheduled;
                final isNoShow = order.pickupStatus == 'NO_SHOW' || order.status == 'NO_SHOW';
                final isReleased = order.pickupStatus == 'RELEASED' || order.status == 'RELEASED';
                final pickupEndAt = order.pickupWindowEndAt != null
                    ? DateTime.tryParse(order.pickupWindowEndAt!)?.toLocal()
                    : null;
                final isExpired = pickupEndAt != null && DateTime.now().isAfter(pickupEndAt);

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // FOOD + ORDER TYPE + STATUS
                        // ==================================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.foodName,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isScheduled
                                          ? Colors.orange.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isScheduled ? "SCHEDULED" : "ASAP",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isScheduled
                                            ? Colors.orange.shade900
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (isReleased
                                        ? Colors.purple
                                        : isNoShow
                                        ? Colors.red
                                        : getStatusColor(order.status))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isReleased
                                    ? 'RELEASED'
                                    : isNoShow
                                    ? 'NO SHOW'
                                    : order.status,
                                style: TextStyle(
                                  color: isReleased
                                      ? Colors.purple
                                      : isNoShow
                                      ? Colors.red
                                      : getStatusColor(order.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Text(
                              'Order #${orderProvider.getOrderId(orderMap)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: order.isFaculty ||
                                        orderProvider.getUserType(orderMap) ==
                                            'Faculty'
                                    ? Colors.deepPurple.shade50
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: order.isFaculty ||
                                          orderProvider.getUserType(orderMap) ==
                                              'Faculty'
                                      ? Colors.deepPurple.shade200
                                      : Colors.blue.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    order.isFaculty ||
                                            orderProvider
                                                    .getUserType(orderMap) ==
                                                'Faculty'
                                        ? Icons.person_rounded
                                        : Icons.school_rounded,
                                    size: 13,
                                    color: order.isFaculty ||
                                            orderProvider
                                                    .getUserType(orderMap) ==
                                                'Faculty'
                                        ? Colors.deepPurple
                                        : Colors.blue.shade800,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.isFaculty ||
                                            orderProvider
                                                    .getUserType(orderMap) ==
                                                'Faculty'
                                        ? 'Faculty'
                                        : 'Student',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: order.isFaculty ||
                                              orderProvider
                                                      .getUserType(orderMap) ==
                                                  'Faculty'
                                          ? Colors.deepPurple
                                          : Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Customer: ${orderProvider.getCustomerName(orderMap)}',
                        ),
                        const SizedBox(height: 8),
                        ...orderProvider
                            .getItems(orderMap)
                            .map(
                              (item) => Text(
                                '${(item['name'] ?? 'Item').toString()} '
                                'x${orderProvider.getItemQuantity(item)} '
                                '₹${orderProvider.getItemTotal(item).toStringAsFixed(0)}',
                              ),
                            ),

                        // SCHEDULED ORDER TIMING BOX
                        if (isScheduled && order.scheduledPickupAt != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                      "Scheduled Pickup: ${_formatIsoTime(order.scheduledPickupAt)}",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.preparationStartAt != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.kitchen, size: 16, color: Colors.deepOrange),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Prepare by: ${_formatIsoTime(order.preparationStartAt)}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.deepOrange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  "Pickup Window: ${_formatIsoWindow(order.scheduledPickupAt, order.pickupWindowEndAt)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Pickup Status: ${order.pickupStatus}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isNoShow || isReleased ? Colors.red : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // ==================================================
                        // BILL BREAKDOWN (Subtotal, GST, Total)
                        // ==================================================
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Item Subtotal:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  Text('₹${order.subtotal.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('GST:', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                                  Text('₹${order.gst.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const Divider(height: 10, thickness: 1),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                  Text(
                                    '₹${order.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        // ==================================================
                        // STATUS MESSAGE
                        // ==================================================
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: isReleased
                                ? Colors.purple.shade50
                                : isNoShow
                                ? Colors.red.shade50
                                : Colors.grey.shade100,

                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Text(
                            isReleased
                                ? 'Uncollected order has been released for replacement/policy preparation.'
                                : isNoShow
                                ? 'Student did not collect during pickup window (NO SHOW).'
                                : getStatusMessage(order.status),

                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: isReleased
                                  ? Colors.purple.shade900
                                  : isNoShow
                                  ? Colors.red.shade900
                                  : Colors.black87,
                            ),
                          ),
                        ),

                        if (orderProvider.getStatus(orderMap) == 'Pending') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final orderId = orderProvider.getOrderId(
                                  orderMap,
                                );
                                final success = await orderProvider
                                    .updateOrderStatus(orderId, 'CONFIRMED');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Order confirmed.'
                                          : 'Failed to confirm order.',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('CONFIRM ORDER'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ] else if (orderProvider.getStatus(orderMap) ==
                            'Confirmed') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final orderId = orderProvider.getOrderId(
                                  orderMap,
                                );
                                final success = await orderProvider
                                    .updateOrderStatus(orderId, 'PREPARING');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Order moved to Preparing.'
                                          : 'Failed to update order.',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.local_fire_department),
                              label: const Text('START PREPARING'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ] else if (orderProvider.getStatus(orderMap) ==
                            'Preparing') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final orderId = orderProvider.getOrderId(
                                  orderMap,
                                );
                                final success = await orderProvider
                                    .updateOrderStatus(orderId, 'READY');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Order marked as Ready for Pickup!'
                                          : 'Failed to update order.',
                                    ),
                                    backgroundColor: success
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('MARK READY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ] else if (orderProvider.getStatus(orderMap) ==
                            'Ready' && !isReleased) ...[
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final orderId = orderProvider.getOrderId(
                                      orderMap,
                                    );
                                    final success = await orderProvider
                                        .updateOrderStatus(orderId, 'COMPLETED');
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Order completed!'
                                              : 'Failed to update order.',
                                        ),
                                        backgroundColor: success
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('COLLECTED'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                  ),
                                ),
                              ),
                              if (isScheduled && (isNoShow || isExpired)) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final orderId = orderProvider.getOrderId(
                                        orderMap,
                                      );
                                      final success = await orderProvider
                                          .releaseUncollectedOrder(orderId);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Uncollected order released.'
                                                : (orderProvider.error ?? 'Failed to release order.'),
                                          ),
                                          backgroundColor: success
                                              ? Colors.purple
                                              : Colors.red,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text(
                                      'RELEASE UNCOLLECTED',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else if (isScheduled && isExpired && !isNoShow) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final orderId = orderProvider.getOrderId(
                                        orderMap,
                                      );
                                      final success = await orderProvider
                                          .markNoShow(orderId);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Order marked as NO SHOW.'
                                                : (orderProvider.error ?? 'Failed to mark NO SHOW.'),
                                          ),
                                          backgroundColor: success
                                              ? Colors.red
                                              : Colors.red,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text(
                                      'NO SHOW',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else if ((isNoShow || isExpired) && !isReleased) ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final orderId = orderProvider.getOrderId(
                                  orderMap,
                                );
                                final success = await orderProvider
                                    .releaseUncollectedOrder(orderId);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Uncollected order released.'
                                          : (orderProvider.error ?? 'Failed to release order.'),
                                    ),
                                    backgroundColor: success
                                        ? Colors.purple
                                        : Colors.red,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('RELEASE UNCOLLECTED ORDER'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
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
