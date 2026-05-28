import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sign_up/controller/app_router.dart';
import 'firebase_options.dart';
import 'view/auth/signin_screen.dart';

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
      title: 'My App',
      debugShowCheckedModeBanner: false,
      home: AppRouter.getInitialScreen(),
    );
  }
}