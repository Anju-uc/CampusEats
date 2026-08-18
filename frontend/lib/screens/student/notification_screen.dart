import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [

          Card(
            child: ListTile(
              leading: Icon(Icons.restaurant, color: Colors.orange),
              title: Text("Order Ready"),
              subtitle: Text(
                "Your order is ready for pickup at the CampusEats counter.",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.local_offer, color: Colors.green),
              title: Text("Today's Special"),
              subtitle: Text(
                "Paneer Butter Masala + Rice ₹99",
              ),
            ),
          ),

          Card(
            child: ListTile(
              leading: Icon(Icons.campaign, color: Colors.blue),
              title: Text("Welcome"),
              subtitle: Text(
                "Welcome to CampusEats. Enjoy your meals!",
              ),
            ),
          ),
        ],
      ),
    );
  }
}