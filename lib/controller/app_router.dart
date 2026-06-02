import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view/auth/signin_screen.dart';
import '../view/home_screen.dart';
import '../view/dashboard/admin_dashboard.dart';
import '../view/dashboard/vendor_dashboard.dart';// <-- NEW: Loading screen
import 'auth_controller.dart';

class AppRouter {
  // 🔄 CHANGED: Now returns a Future because role check is async
  static Future<Widget> getInitialScreen() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SignInScreen();
    }

    // Read role from Firestore
    String role = await AuthController.getUserRole();

    if (role == 'admin') {
      return const AdminDashboard();
    } else if (role == 'vendor') {
      return const VendorDashboard();
    } else {
      return const HomeScreen();
    }
  }

  // Navigate based on role (still works the same)
  static Future<void> navigateBasedOnRole(BuildContext context) async {
    String role = await AuthController.getUserRole();
    Widget destination;

    if (role == 'admin') {
      destination = const AdminDashboard();
    } else if (role == 'vendor') {
      destination = const VendorDashboard();
    } else {
      destination = const HomeScreen();
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }
}