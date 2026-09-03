import 'package:flutter/material.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final List<Map<String, dynamic>> orders = [
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

  void updateStatus(int index, String status) {
    setState(() {
      orders[index]['status'] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Order #${orders[index]['id']} marked as $status',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text(
          'CampusEATS Admin',
          style: TextStyle(
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
          // Dashboard heading
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Manage cafeteria orders',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // Order list
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

                              // Order number + status
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
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 15),

                              // Roll number
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

                              // Cafeteria
                              Row(
                                children: [
                                  const Icon(
                                    Icons.restaurant,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    order['cafeteria'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Items
                              Text(
                                order['items'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Total
                              Text(
                                '₹${order['total'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 15),

                              // Preparing button
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

                              // Ready + Completed
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

                              // Cancel
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
}