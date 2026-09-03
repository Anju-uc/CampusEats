import 'package:flutter/material.dart';

import '../student/home_screen.dart';
import '../kitchen/kitchen_dashboard.dart';
import '../kitchen/admin_dashboard.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void openRole(BuildContext context, String role) {
    if (role == "Student" || role == "Teacher") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            role: role,
          ),
        ),
      );
    } else if (role == "Kitchen Staff") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const KitchenDashboard(),
        ),
      );
    } else if (role == "Admin") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // LOGO
              Container(
                width: 82,
                height: 82,

                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: 45,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "CampusEats",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "PES University Food Ordering",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 45),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Welcome! 👋",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF222222),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "How would you like to continue?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // STUDENT
              RoleCard(
                icon: Icons.school_rounded,
                title: "Student",
                subtitle: "Order food using your PESU ID",
                color: Colors.orange,
                onTap: () {
                  openRole(context, "Student");
                },
              ),

              const SizedBox(height: 16),

              // TEACHER
              RoleCard(
                icon: Icons.person_rounded,
                title: "Teacher",
                subtitle: "Order food using your university ID",
                color: Colors.deepOrange,
                onTap: () {
                  openRole(context, "Teacher");
                },
              ),

              const SizedBox(height: 16),

              // KITCHEN
              RoleCard(
                icon: Icons.restaurant_rounded,
                title: "Kitchen Staff",
                subtitle: "Manage incoming food orders",
                color: Colors.green,
                onTap: () {
                  openRole(context, "Kitchen Staff");
                },
              ),

              const SizedBox(height: 16),

              // ADMIN
              RoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: "Administrator",
                subtitle: "Manage menu, sales and cafeterias",
                color: Colors.blue,
                onTap: () {
                  openRole(context, "Admin");
                },
              ),

              const SizedBox(height: 35),

              Container(
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),

                  border: Border.all(
                    color: Colors.orange.withOpacity(0.15),
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.orange,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        "Your account type determines which CampusEats features you can access.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ======================================================
// ROLE CARD
// ======================================================

class RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),

        child: Container(
          padding: const EdgeInsets.all(18),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: Colors.grey.shade200,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(17),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}