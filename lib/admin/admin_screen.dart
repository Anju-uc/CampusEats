import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  final String cafeteriaId;
  final String cafeteriaName;

  const AdminScreen({
    super.key,
    required this.cafeteriaId,
    required this.cafeteriaName,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final List<Map<String, dynamic>> allOrders = [
    {
      'id': 1001,
      'rollNumber': 'PESU001',
      'cafeteria': 'Bengaluru Cafe',
      'items': 'Masala Dosa x 2, Coffee x 1',
      'total': 180.0,
      'status': 'Preparing',
    },
    {
      'id': 1002,
      'rollNumber': 'PESU002',
      'cafeteria': 'Cafe PESU',
      'items': 'Pizza x 1, French Fries x 1',
      'total': 250.0,
      'status': 'Ready',
    },
    {
      'id': 1003,
      'rollNumber': 'PESU003',
      'cafeteria': 'Non-Veg Cafeteria',
      'items': 'Chicken Biryani x 1',
      'total': 180.0,
      'status': 'Completed',
    },
  ];

  List<Map<String, dynamic>> get cafeteriaOrders {
    return allOrders
        .where((order) => order['cafeteria'] == widget.cafeteriaName)
        .toList();
  }

  void updateStatus(int index, String status) {
    final order = cafeteriaOrders[index];

    setState(() {
      order['status'] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order #${order['id']} marked as $status',
        ),
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Preparing':
        return Colors.orange;
      case 'Ready':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int get totalOrders => cafeteriaOrders.length;

  int get pendingOrders {
    return cafeteriaOrders
        .where(
          (order) =>
              order['status'] != 'Completed' &&
              order['status'] != 'Cancelled',
        )
        .length;
  }

  int get completedOrders {
    return cafeteriaOrders
        .where((order) => order['status'] == 'Completed')
        .length;
  }

  double get revenue {
    return cafeteriaOrders
        .where((order) => order['status'] != 'Cancelled')
        .fold(
          0.0,
          (sum, order) => sum + (order['total'] as double),
        );
  }

  @override
  Widget build(BuildContext context) {
    final orders = cafeteriaOrders;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          widget.cafeteriaName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Manage ${widget.cafeteriaName}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Orders',
                    totalOrders.toString(),
                    Icons.receipt_long,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Pending',
                    pendingOrders.toString(),
                    Icons.pending_actions,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Completed',
                    completedOrders.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.currency_rupee,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Revenue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Total completed/active orders',
                ),
                trailing: Text(
                  '₹${revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: orders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final String status = order['status'];

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 16,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order['id']}',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color:
                                            getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Roll No: ${order['rollNumber']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.cafeteriaName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                order['items'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                '₹${order['total'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    updateStatus(
                                      index,
                                      'Preparing',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.restaurant,
                                  ),
                                  label: const Text(
                                    'Preparing',
                                  ),
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.orange,
                                    foregroundColor:
                                        Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        updateStatus(
                                          index,
                                          'Ready',
                                        );
                                      },
                                      child: const Text(
                                        'Ready',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        updateStatus(
                                          index,
                                          'Completed',
                                        );
                                      },
                                      child: const Text(
                                        'Completed',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () {
                                    updateStatus(
                                      index,
                                      'Cancelled',
                                    );
                                  },
                                  child: const Text(
                                    'Cancel Order',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
