import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/menu_provider.dart';

import 'screens/auth/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // ==========================
        // CART PROVIDER
        // ==========================
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),

        // ==========================
        // ORDER PROVIDER
        // ==========================
        ChangeNotifierProvider(
          create: (_) => OrderProvider(),
        ),

        // ==========================
        // MENU PROVIDER
        // ==========================
        ChangeNotifierProvider(
          create: (_) => MenuProvider(),
        ),
      ],

      // ==========================
      // MAIN APP
      // ==========================
      child: const CampusEats(),
    ),
  );
}

class CampusEats extends StatelessWidget {
  const CampusEats({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'CampusEats',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
        ),

        scaffoldBackgroundColor:
            const Color(0xFFFFF9F4),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      // ==========================
      // FIRST SCREEN
      // ==========================

      home: const SplashScreen(),
    );
  }
}