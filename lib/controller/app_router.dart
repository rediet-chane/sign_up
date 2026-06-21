import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view/auth/signin_screen.dart';
import '../view/home_screen.dart';
import '../view/dashboard/admin_dashboard.dart';
import '../view/dashboard/vendor_dashboard.dart';
import '../view/pending_approval_screen.dart';
import 'user_service.dart';

class AppRouter {
  static Future<Widget> getInitialScreen() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final User? user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const SignInScreen();
    }

    UserService userService = UserService();
    String? role = await userService.getCurrentUserRole();
    String? status = await userService.getCurrentUserStatus();

    if (role == 'admin') return const AdminDashboard();
    if (role == 'vendor' && status == 'pending') return const PendingApprovalScreen();
    if (role == 'vendor') return const VendorDashboard();
    
    return const HomeScreen();
  }

  static Future<void> navigateBasedOnRole(BuildContext context) async {
    UserService userService = UserService();
    String? role = await userService.getCurrentUserRole();
    String? status = await userService.getCurrentUserStatus();
    Widget destination;

    if (role == 'admin') {
      destination = const AdminDashboard();
    } else if (role == 'vendor' && status == 'pending') {
      destination = const PendingApprovalScreen();
    } else if (role == 'vendor') {
      destination = const VendorDashboard();
    } else {
      destination = const HomeScreen();
    }

    if (context.mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => destination));
    }
  }
}