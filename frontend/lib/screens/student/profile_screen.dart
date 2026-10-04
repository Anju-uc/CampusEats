import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';
import '../auth/role_selection_screen.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';

class ProfileScreen extends StatelessWidget {
  final String role;

  const ProfileScreen({super.key, this.role = "Student"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),

            const SizedBox(height: 15),

            Text(
              role == "Student"
                  ? (ApiService.studentName ?? "Student")
                  : (ApiService.facultyName ??
                        (role == "Teacher"
                            ? "Faculty"
                            : (ApiService.adminTitle ?? role))),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              role == "Student"
                  ? '${ApiService.studentProgram ?? "Student"} Student'
                  : '${ApiService.facultyProgram ?? "Faculty"} ${role == "Teacher" ? "Faculty" : role}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: Colors.orange),
                title: const Text("College"),
                subtitle: const Text("PES University"),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.orange),
                title: Text(role == "Student" ? "Student ID" : "Session"),
                subtitle: Text(
                  role == "Student"
                      ? (ApiService.studentId ?? "Student Account")
                      : (ApiService.facultyId ??
                            (role == "Teacher"
                                ? "Faculty Account"
                                : "Authenticated")),
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.orange),
                title: const Text("Account Type"),
                subtitle: Text(
                  role == "Student"
                      ? "Student"
                      : (role == "Teacher" ? "Faculty" : role),
                ),
              ),
            ),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange,
                ),
                title: const Text("Status"),
                subtitle: Text(
                  role == "Student"
                      ? (ApiService.studentStatus ?? "ACTIVE")
                      : "ACTIVE",
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (role == "Student") {
                    await ApiService.clearStudentSession();
                  } else if (role == "Teacher") {
                    await ApiService.clearFacultySession();
                  } else if (role == "Admin") {
                    await ApiService.clearAdminSession();
                  }
                  if (context.mounted) {
                    context.read<OrderProvider>().clearOrders();
                    context.read<CartProvider>().clearSession();
                  }
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => role == "Student"
                          ? const LoginScreen(role: "Student")
                          : const RoleSelectionScreen(),
                    ),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text(
                  "LOG OUT",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
