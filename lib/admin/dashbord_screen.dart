import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'menu_management.dart';
import 'order_screen.dart';
import 'user_screen.dart';

class DashbordScreen extends StatefulWidget {
  const DashbordScreen({super.key});

  @override
  State<DashbordScreen> createState() => _DashbordScreenState();
}

class _DashbordScreenState extends State<DashbordScreen> {
  List<Map<String, dynamic>> cafeterias = [];
  List<Map<String, dynamic>> orders = [];
  Map<String, dynamic> analytics = {};

  bool loading = true;
  bool cafeteriaOpen = true;
  int selectedCafeteria = 0;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final cafeteriaData = await ApiService.getCafeterias();
      final orderData = await ApiService.getOrders();
      final analyticsData = await ApiService.getAnalytics();

      if (!mounted) return;

      setState(() {
        cafeterias = cafeteriaData
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        orders = orderData
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        analytics = Map<String, dynamic>.from(analyticsData);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard: $e'),
        ),
      );
    }
  }

  String get cafeteriaName {
    if (cafeterias.isEmpty) {
      return 'PESU Cafeteria 1';
    }

    return cafeterias[selectedCafeteria]['name']?.toString() ??
        'PESU Cafeteria ${selectedCafeteria + 1}';
  }

  int get totalOrders {
    return orders.length;
  }

  int get pendingOrders {
    return orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';

      return status == 'pending' || status == 'confirmed';
    }).length;
  }

  int get completedOrders {
    return orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';

      return status == 'completed';
    }).length;
  }

  double get revenue {
    double total = 0;

    for (final order in orders) {
      final value =
          order['total_amount'] ?? order['total'] ?? order['amount'];

      if (value is num) {
        total += value.toDouble();
      } else {
        total += double.tryParse(value?.toString() ?? '') ?? 0;
      }
    }

    return total;
  }

  List<Map<String, dynamic>> get newOrders {
    return orders.where((order) {
      final status = order['status']?.toString().toLowerCase() ?? '';

      return status == 'pending' || status == 'confirmed';
    }).take(3).toList();
  }

  Future<void> acceptOrder(Map<String, dynamic> order) async {
    final id = order['id'];

    if (id == null) return;

    try {
      await ApiService.updateOrderStatus(id, 'Preparing');
      await loadDashboard();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order accepted and moved to Preparing',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update order: $e'),
        ),
      );
    }
  }

  void openMenu() {
    if (cafeterias.isEmpty) return;

    final cafeteria = cafeterias[selectedCafeteria];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MenuManagement(
          restaurantId: cafeteria['id'].toString(),
          restaurantName: cafeteria['name']?.toString() ??
              'PESU Cafeteria ${selectedCafeteria + 1}',
        ),
      ),
    );
  }

  void openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderScreen(),
      ),
    );
  }

  void openUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserScreen(),
      ),
    );
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        top: 20,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(title),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        title: const Text(
          'CampusEATS Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              sectionTitle('🏫 Select Cafeteria'),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedCafeteria,
                    isExpanded: true,
                    items: List.generate(
                      cafeterias.length,
                      (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text(
                            cafeterias[index]['name']?.toString() ??
                                'PESU Cafeteria ${index + 1}',
                          ),
                        );
                      },
                    ),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        selectedCafeteria = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.restaurant),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            cafeteriaName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            cafeteriaOpen
                                ? '🟢 Cafeteria is OPEN'
                                : '🔴 Cafeteria is CLOSED',
                            style: TextStyle(
                              color: cafeteriaOpen
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: cafeteriaOpen,
                      onChanged: (value) {
                        setState(() {
                          cafeteriaOpen = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              sectionTitle('📊 Overview'),

              Row(
                children: [
                  statCard(
                    'Total Orders',
                    totalOrders.toString(),
                    Icons.shopping_bag,
                  ),
                  statCard(
                    'Pending',
                    pendingOrders.toString(),
                    Icons.pending_actions,
                  ),
                ],
              ),

              Row(
                children: [
                  statCard(
                    'Completed',
                    completedOrders.toString(),
                    Icons.check_circle,
                  ),
                  statCard(
                    'Revenue',
                    '₹${revenue.toStringAsFixed(0)}',
                    Icons.currency_rupee,
                  ),
                ],
              ),

              sectionTitle('⚡ Quick Actions'),

              Row(
                children: [
                  actionButton(
                    'Menu',
                    Icons.restaurant_menu,
                    openMenu,
                  ),
                  actionButton(
                    'Orders',
                    Icons.receipt_long,
                    openOrders,
                  ),
                ],
              ),

              Row(
                children: [
                  actionButton(
                    'Users',
                    Icons.people,
                    openUsers,
                  ),
                  actionButton(
                    'Analytics',
                    Icons.bar_chart,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Detailed Analytics coming next',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              sectionTitle('🔔 New Orders'),

              if (newOrders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 45,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No new orders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              ...newOrders.map(
                (order) {
                  final id =
                      order['id']?.toString() ?? '-';

                  final items =
                      order['items']?.toString() ??
                          'Food order';

                  final amount =
                      order['total_amount'] ??
                          order['total'] ??
                          order['amount'] ??
                          0;

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        width: 1,
                        color: Colors.orange.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Order #$id',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          items,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₹$amount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                acceptOrder(order),
                            child: const Text(
                              'ACCEPT ORDER',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              sectionTitle('🔥 Popular Items'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    ListTile(
                      leading: Text(
                        '🥇',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      title: Text('Masala Dosa'),
                      trailing: Text('Popular'),
                    ),
                    ListTile(
                      leading: Text(
                        '🥈',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      title: Text('Chicken Biryani'),
                      trailing: Text('Popular'),
                    ),
                    ListTile(
                      leading: Text(
                        '🥉',
                        style: TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      title: Text('Pizza'),
                      trailing: Text('Popular'),
                    ),
                  ],
                ),
              ),

              sectionTitle('🕐 Peak Hours'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    peakHour('12 PM', 0.95),
                    peakHour('1 PM', 0.80),
                    peakHour('2 PM', 0.60),
                    peakHour('11 AM', 0.40),
                  ],
                ),
              ),

              sectionTitle('📈 Quick Analytics'),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    analyticsRow(
                      'Total Orders',
                      totalOrders.toString(),
                    ),
                    analyticsRow(
                      'Pending Orders',
                      pendingOrders.toString(),
                    ),
                    analyticsRow(
                      'Completed Orders',
                      completedOrders.toString(),
                    ),
                    analyticsRow(
                      'Total Revenue',
                      '₹${revenue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget peakHour(
    String time,
    double value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget analyticsRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}