import 'package:flutter/material.dart';
import 'dashbord_screen.dart';
import 'menu_management.dart';
import 'order_screen.dart';
import 'user_screen.dart';

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
  void openDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashbordScreen(
          cafeteriaId: widget.cafeteriaId,
          cafeteriaName: widget.cafeteriaName,
        ),
      ),
    );
  }

  void openMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuManagement(
          restaurantId: widget.cafeteriaId,
          restaurantName: widget.cafeteriaName,
        ),
      ),
    );
  }

  void openOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(
          cafeteriaId: widget.cafeteriaId,
          cafeteriaName: widget.cafeteriaName,
        ),
      ),
    );
  }

  void openUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserScreen(
          cafeteriaId: widget.cafeteriaId,
          cafeteriaName: widget.cafeteriaName,
        ),
      ),
    );
  }

  Widget managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          '${widget.cafeteriaName} Admin',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.orange.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.cafeteriaName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your cafeteria',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Management',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            managementCard(
              icon: Icons.dashboard,
              title: 'Dashboard',
              subtitle:
                  'View orders, revenue and cafeteria analytics',
              color: Colors.orange,
              onTap: openDashboard,
            ),
            managementCard(
              icon: Icons.restaurant_menu,
              title: 'Menu Management',
              subtitle:
                  'Add, edit, delete and manage food availability',
              color: Colors.green,
              onTap: openMenu,
            ),
            managementCard(
              icon: Icons.receipt_long,
              title: 'Order Management',
              subtitle:
                  'View and update customer orders',
              color: Colors.blue,
              onTap: openOrders,
            ),
            managementCard(
              icon: Icons.people,
              title: 'Users',
              subtitle:
                  'View students who ordered from this cafeteria',
              color: Colors.purple,
              onTap: openUsers,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.orange.shade100,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You are logged in as ${widget.cafeteriaName} admin.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
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
}
