import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../view/auth/signin_screen.dart';
import '../view/home_screen.dart';
import '../view/dashboard/admin_dashboard.dart';
import '../view/dashboard/vendor_dashboard.dart';
import 'auth_controller.dart';

class AppRouter {
  static Widget getInitialScreen(){
    final User? user = FirebaseAuth.instance.currentUser;
    if(user == null){
      return const SignInScreen();
    }

    String role = AuthController.getUserRole(user); 
    if(role == 'admin'){
      return const AdminDashboard();
    } else if(role == 'vendor'){
      return const VendorDashboard();
    } else {
      return const HomeScreen();
    }
  }
  
  static void navigateBasedOnRole(BuildContext context, User user) {
    String role = AuthController.getUserRole(user);
    Widget destination;
    if(role == 'admin'){
      destination = const AdminDashboard();
    } else if(role == 'vendor'){
      destination = const VendorDashboard();
    } else {
      destination = const HomeScreen();
    }
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (context) => destination)
      );
  }
}
      