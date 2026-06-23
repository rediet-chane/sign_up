import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'view/auth/signin_screen.dart';
import 'controller/app_router.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'Awura Marketplace',
      theme: ThemeData(primarySwatch: Colors.blue),
      // ✅ Session persistence: Check if user is logged in on startup
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Still loading Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // User is logged in → Route to correct dashboard
          if (snapshot.hasData) {
            return const _AutoRoute();
          }
          
          // Not logged in → Show login screen
          return const SignInScreen();
        },
      ),
    );
  }
}

// ✅ Uses your EXISTING AppRouter - no new files needed
class _AutoRoute extends StatefulWidget {
  const _AutoRoute({super.key});

  @override
  State<_AutoRoute> createState() => _AutoRouteState();
}

class _AutoRouteState extends State<_AutoRoute> {
  @override
  void initState() {
    super.initState();
    // Navigate using your existing router after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppRouter.navigateBasedOnRole(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}