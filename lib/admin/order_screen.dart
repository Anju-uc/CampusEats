import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  List<dynamic> orders = [];
  bool loading = true;
  String filter = 'All';

  final List<String> statuses = [
    'Pending',
    'Preparing',
    'Ready',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() => loading = true);

    try {
      final result = await ApiService.getOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: $e'),
        ),
      );
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await ApiService.updateOrderStatus(id, status);
      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$id updated to $status'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
        ),
      );
    }
  }

  Future<void> deleteOrder(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Order'),
          content: Text('Delete order #$id?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteOrder(id);
      await loadOrders();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete order: $e'),
        ),
      );
    }
  }

  List<dynamic> get filteredOrders {
    if (filter == 'All') {
      return orders;
    }

    return orders.where((order) {
      if (order is! Map) return false;

      final status =
          order['status']?.toString().toLowerCase() ?? '';

      return status == filter.toLowerCase();
    }).toList();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getFoodName(Map order) {
    final items = order['items'];

    if (items is List && items.isNotEmpty) {
      return items.map((item) {
        if (item is Map) {
          return item['name']?.toString() ?? 'Food';
        }
        return 'Food';
      }).join(', ');
    }

    if (items is String && items.isNotEmpty) {
      try {
        final decoded = jsonDecode(items);

        if (decoded is List && decoded.isNotEmpty) {
          return decoded.map((item) {
            if (item is Map) {
              return item['name']?.toString() ?? 'Food';
            }
            return 'Food';
          }).join(', ');
        }
      } catch (_) {}

      final match = RegExp(
        r'name:\s*([^,}]+)',
        caseSensitive: false,
      ).firstMatch(items);

      if (match != null) {
        return match.group(1)?.trim() ?? 'Food Order';
      }
    }

    return order['foodName']?.toString() ??
        order['food_name']?.toString() ??
        'Food Order';
  }

  double getOrderTotal(Map order) {
    final totalAmount = order['total_amount'];

    if (totalAmount != null) {
      return double.tryParse(totalAmount.toString()) ?? 0;
    }

    final total = order['total'];

    if (total != null) {
      return double.tryParse(total.toString()) ?? 0;
    }

    final amount = order['amount'];

    if (amount != null) {
      return double.tryParse(amount.toString()) ?? 0;
    }

    final items = order['items'];

    if (items is List) {
      double result = 0;

      for (final item in items) {
        if (item is Map) {
          final price =
              double.tryParse(item['price']?.toString() ?? '') ?? 0;

          final quantity =
              double.tryParse(item['quantity']?.toString() ?? '') ?? 1;

          result += price * quantity;
        }
      }

      return result;
    }

    if (items is String && items.isNotEmpty) {
      try {
        final decoded = jsonDecode(items);

        if (decoded is List) {
          double result = 0;

          for (final item in decoded) {
            if (item is Map) {
              final price =
                  double.tryParse(item['price']?.toString() ?? '') ?? 0;

              final quantity =
                  double.tryParse(item['quantity']?.toString() ?? '') ?? 1;

              result += price * quantity;
            }
          }

          if (result > 0) {
            return result;
          }
        }
      } catch (_) {}

      final totalPriceMatch = RegExp(
        r'totalPrice:\s*([0-9]+(?:\.[0-9]+)?)',
        caseSensitive: false,
      ).firstMatch(items);

      if (totalPriceMatch != null) {
        return double.tryParse(
              totalPriceMatch.group(1)!,
            ) ??
            0;
      }

      final priceMatch = RegExp(
        r'price:\s*([0-9]+(?:\.[0-9]+)?)',
        caseSensitive: false,
      ).firstMatch(items);

      if (priceMatch != null) {
        return double.tryParse(
              priceMatch.group(1)!,
            ) ??
            0;
      }
    }

    return 0;
  }

  Widget orderCard(Map order) {
    final id = int.tryParse(
          order['id']?.toString() ?? '',
        ) ??
        0;

    final foodName = getFoodName(order);
    final total = getOrderTotal(order);

    final date = order['date']?.toString() ??
        order['createdAt']?.toString() ??
        '';

    final currentStatus =
        order['status']?.toString() ?? 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(id.toString()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$id',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (date.isNotEmpty)
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => deleteOrder(id),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            Text(
              foodName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ₹${total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: statuses.contains(currentStatus)
                        ? currentStatus
                        : 'Pending',
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: statusColor(
                        currentStatus,
                      ).withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                    items: statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null &&
                          value != currentStatus) {
                        updateStatus(id, value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedOrders = filteredOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              children: [
                'All',
                ...statuses,
              ].map((status) {
                final selected = filter == status;

                return Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        filter = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : displayedOrders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: loadOrders,
                        child: ListView(
                          children: const [
                            SizedBox(height: 180),
                            Center(
                              child: Text(
                                'No orders found',
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadOrders,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.all(16),
                          itemCount:
                              displayedOrders.length,
                          itemBuilder:
                              (context, index) {
                            final order =
                                displayedOrders[index];

                            if (order is Map) {
                              return orderCard(order);
                            }

                            return const SizedBox();
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}