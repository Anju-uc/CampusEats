import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<Map<String, dynamic>> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
    });

    try {
      final orders = await ApiService.getOrders();

      final Map<String, Map<String, dynamic>> uniqueUsers = {};

      for (final order in orders) {
        if (order is! Map) continue;

        final name =
            order['student_name']?.toString() ??
            order['studentName']?.toString() ??
            order['name']?.toString() ??
            'Student';

        final email =
            order['student_email']?.toString() ??
            order['studentEmail']?.toString() ??
            order['email']?.toString() ??
            'No email';

        final key = email != 'No email'
            ? email
            : name;

        if (!uniqueUsers.containsKey(key)) {
          uniqueUsers[key] = {
            'name': name,
            'email': email,
            'orders': 1,
          };
        } else {
          uniqueUsers[key]!['orders'] =
              (uniqueUsers[key]!['orders'] as int) + 1;
        }
      }

      if (!mounted) return;

      setState(() {
        users = uniqueUsers.values.toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load users: $e',
          ),
        ),
      );
    }
  }

  Widget userCard(Map<String, dynamic> user) {
    final name = user['name']?.toString() ?? 'Student';
    final email =
        user['email']?.toString() ?? 'No email';
    final orderCount =
        user['orders']?.toString() ?? '0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          radius: 26,
          child: Text(
            name.isNotEmpty
                ? name[0].toUpperCase()
                : 'S',
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(email),
              const SizedBox(height: 4),
              Text(
                '$orderCount order${orderCount == '1' ? '' : 's'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : users.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadUsers,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Icon(
                        Icons.people_outline,
                        size: 60,
                      ),
                      SizedBox(height: 15),
                      Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadUsers,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${users.length} Students',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ...users.map(
                        (user) => userCard(user),
                      ),
                    ],
                  ),
                ),
    );
  }
}