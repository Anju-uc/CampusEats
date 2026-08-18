import 'package:flutter/material.dart';

import '../student/home_screen.dart';
import '../kitchen/kitchen_dashboard.dart';
import '../kitchen/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    this.role = "Student",
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController idController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =====================================================
  // ROLE DETAILS
  // =====================================================

  String get roleTitle {
    switch (widget.role) {
      case "Teacher":
        return "Teacher Login";

      case "Kitchen Staff":
        return "Kitchen Staff Login";

      case "Admin":
        return "Administrator Login";

      default:
        return "Student Login";
    }
  }

  String get idLabel {
    switch (widget.role) {
      case "Teacher":
        return "Faculty ID";

      case "Kitchen Staff":
        return "Staff ID";

      case "Admin":
        return "Admin ID";

      default:
        return "PES Student ID";
    }
  }

  IconData get roleIcon {
    switch (widget.role) {
      case "Teacher":
        return Icons.person_rounded;

      case "Kitchen Staff":
        return Icons.restaurant_rounded;

      case "Admin":
        return Icons.admin_panel_settings_rounded;

      default:
        return Icons.school_rounded;
    }
  }

  Color get roleColor {
    switch (widget.role) {
      case "Teacher":
        return Colors.deepOrange;

      case "Kitchen Staff":
        return Colors.green;

      case "Admin":
        return Colors.blue;

      default:
        return Colors.orange;
    }
  }

  // =====================================================
  // DEMO LOGIN
  // =====================================================

  void login() {
    final id = idController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      showMessage(
        "Please enter your ID and password",
        Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Small delay to make login feel realistic.
    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;

        bool valid = false;

        // =================================================
        // DEMO ACCOUNTS
        // =================================================

        switch (widget.role) {
          case "Student":
            valid =
                (id == "student" ||
                    id == "student@pes.edu" ||
                    id.startsWith("pes")) &&
                password == "1234";
            break;

          case "Teacher":
            valid =
                (id == "teacher" ||
                    id == "teacher@pes.edu" ||
                    id.startsWith("faculty")) &&
                password == "1234";
            break;

          case "Kitchen Staff":
            valid =
                (id == "kitchen" ||
                    id == "kitchen@campuseats.com") &&
                password == "1234";
            break;

          case "Admin":
            valid =
                (id == "admin" ||
                    id == "admin@campuseats.com") &&
                password == "1234";
            break;
        }

        setState(() {
          isLoading = false;
        });

        if (!valid) {
          showMessage(
            "Invalid ${widget.role} ID or password",
            Colors.red,
          );
          return;
        }

        // =================================================
        // OPEN CORRECT DASHBOARD
        // =================================================

        if (widget.role == "Student" ||
            widget.role == "Teacher") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        } else if (widget.role == "Kitchen Staff") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const KitchenDashboard(),
            ),
          );
        } else if (widget.role == "Admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AdminDashboard(),
            ),
          );
        }
      },
    );
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            30,
            24,
            30,
          ),

          child: Column(
            children: [
              // =================================================
              // TOP LOGO
              // =================================================

              Container(
                width: 85,
                height: 85,

                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius:
                      BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color:
                          roleColor.withOpacity(0.25),
                      blurRadius: 20,
                      offset:
                          const Offset(0, 8),
                    ),
                  ],
                ),

                child: Icon(
                  roleIcon,
                  color: Colors.white,
                  size: 42,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "CampusEats",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                "PES University Food Ordering",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 35),

              // =================================================
              // ROLE TITLE
              // =================================================

              Text(
                roleTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade900,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Sign in to continue to CampusEats",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // ROLE BADGE
              // =================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color:
                      roleColor.withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(30),
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roleIcon,
                      size: 19,
                      color: roleColor,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      widget.role,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // =================================================
              // ID FIELD
              // =================================================

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  idLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: idController,

                textInputAction:
                    TextInputAction.next,

                decoration: InputDecoration(
                  hintText: _getIdHint(),

                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: roleColor,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: roleColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PASSWORD
              // =================================================

              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  "Password",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,

                obscureText: hidePassword,

                onSubmitted: (_) {
                  login();
                },

                decoration: InputDecoration(
                  hintText: "Enter your password",

                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: roleColor,
                  ),

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword =
                            !hidePassword;
                      });
                    },

                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: roleColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // =================================================
              // FORGOT PASSWORD
              // =================================================

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  onPressed: () {
                    showMessage(
                      "Password recovery will be added next.",
                      Colors.orange,
                    );
                  },

                  child: const Text(
                    "Forgot Password?",
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // LOGIN BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : login,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor: roleColor,
                    foregroundColor:
                        Colors.white,

                    elevation: 4,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================
              // DEMO ACCOUNT INFORMATION
              // =================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),

                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: roleColor,
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          "Demo Login",
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "ID: ${_getDemoId()}",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      "Password: 1234",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              Text(
                "CampusEats • PES University",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getIdHint() {
    switch (widget.role) {
      case "Teacher":
        return "Example: faculty";

      case "Kitchen Staff":
        return "Example: kitchen";

      case "Admin":
        return "Example: admin";

      default:
        return "Example: student";
    }
  }

  String _getDemoId() {
    switch (widget.role) {
      case "Teacher":
        return "teacher";

      case "Kitchen Staff":
        return "kitchen";

      case "Admin":
        return "admin";

      default:
        return "student";
    }
  }
}