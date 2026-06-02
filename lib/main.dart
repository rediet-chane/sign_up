import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controller/app_router.dart';
import 'view/loading_screen.dart';
import 'view/auth/signin_screen.dart'; // ✅ ADDED THIS IMPORT

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Awura Marketplace',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: AppRouter.getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          if (snapshot.hasError) {
            return const SignInScreen();
          }
          return snapshot.data ?? const SignInScreen();
        },
      ),
    );
  }
}