import 'package:flutter/material.dart';
import 'dart:async';

import 'package:provider/provider.dart';

import 'role_selection_screen.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../student/home_screen.dart';
import '../kitchen/admin_dashboard.dart';
import '../kitchen/kitchen_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _tryRestoreSession();
    });
  }

  /// Attempts to restore a persisted session after app start or browser refresh.
  /// On success routes directly to the correct dashboard; otherwise falls back
  /// to RoleSelectionScreen.
  Future<void> _tryRestoreSession() async {
    try {
      final storedRole = await ApiService.getStoredActiveRole();
      if (!mounted) return;

      if (storedRole == 'student') {
        final ok = await ApiService.restoreStudentSession();
        if (ok && mounted) {
          final userKey =
              'student:${ApiService.studentUid ?? ApiService.studentId}';
          await context.read<CartProvider>().switchSession(
            userKey,
            useBackend: true,
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(role: 'Student'),
            ),
          );
          return;
        }
      } else if (storedRole == 'teacher') {
        final ok = await ApiService.restoreFacultySession();
        if (ok && mounted) {
          final userKey = 'faculty:${ApiService.facultyId}';
          await context.read<CartProvider>().switchSession(
            userKey,
            useBackend: true,
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(role: 'Teacher'),
            ),
          );
          return;
        }
      } else if (storedRole == 'admin') {
        final ok = await ApiService.restoreAdminSession();
        if (ok && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
          return;
        }
      } else if (storedRole == 'kitchen') {
        final ok = await ApiService.restoreKitchenSession();
        if (ok && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const KitchenDashboard()),
          );
          return;
        }
      }
    } catch (_) {
      // Ignore any restoration errors — fall through to role selection.
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container
              Container(
                width: 125,
                height: 125,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 70,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "CampusEats",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "PES University",
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Smart Campus Food Ordering",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 50),

              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Good food. Less waiting. 🍽️",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
