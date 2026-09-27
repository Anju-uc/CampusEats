import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final studentIdController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    studentIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final studentId = studentIdController.text.trim().toUpperCase();
    final password = passwordController.text;
    final confirmation = confirmPasswordController.text;

    if (studentId.isEmpty) {
      _showMessage('Enter your PES SRN', Colors.red);
      return;
    }
    if (password.isEmpty) {
      _showMessage('Enter a password', Colors.red);
      return;
    }
    if (confirmation.isEmpty) {
      _showMessage('Confirm your password', Colors.red);
      return;
    }
    if (password != confirmation) {
      _showMessage('Passwords do not match', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService.registerStudent(studentId, password);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully. You can now log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(role: 'Student')),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error), Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    final normalized = message.toLowerCase();

    if (normalized.contains('not authorized') ||
        normalized.contains('not eligible')) {
      return 'This SRN is not eligible for student registration.';
    }
    if (normalized.contains('already registered')) {
      return 'This SRN already has a student account.';
    }
    if (normalized.contains('password')) {
      return 'Choose a stronger password and try again.';
    }
    if (normalized.contains('reach') || normalized.contains('timed out')) {
      return message;
    }
    return message.isEmpty ? 'Registration failed. Please try again.' : message;
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _decoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.badge_outlined, color: Colors.orange),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.orange, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F1),
      appBar: AppBar(
        title: const Text('Create Student Account'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.school_rounded, color: Colors.orange, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Register with your PES SRN',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your official student details will be loaded from the PES registry.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: studentIdController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration: _decoration('PES SRN'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: hidePassword,
                textInputAction: TextInputAction.next,
                decoration: _decoration(
                  'Password',
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                onSubmitted: (_) => register(),
                decoration: _decoration(
                  'Confirm Password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => hideConfirmPassword = !hideConfirmPassword,
                    ),
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Already registered? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
