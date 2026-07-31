import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'view/auth/signin_screen.dart';
import 'controller/app_router.dart';
import 'controller/user_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// One channel, reused everywhere (foreground popup, background handler,
// and the AndroidManifest default-channel meta-data).
const AndroidNotificationChannel vendorAlertsChannel = AndroidNotificationChannel(
  'vendor_alerts',
  'Vendor Alerts',
  description: 'Notifications for new vendor signups',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 Background message: ${message.notification?.title}');
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  await flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        vendorAlertsChannel.id,
        vendorAlertsChannel.name,
        channelDescription: vendorAlertsChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- Local notifications setup ---
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(vendorAlertsChannel);

  // --- FCM setup ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  String? token = await messaging.getToken();
  debugPrint('🔔 FCM TOKEN: $token');

  if (token != null && FirebaseAuth.instance.currentUser != null) {
    await UserService().saveFCMToken(token);
  }

  messaging.onTokenRefresh.listen((newToken) async {
    debugPrint('🔔 Token refreshed: $newToken');
    if (FirebaseAuth.instance.currentUser != null) {
      await UserService().saveFCMToken(newToken);
    }
  });

  // Show a popup whenever a message arrives while the app is OPEN.
  // This is the piece that was missing — without it, foreground messages
  // are delivered silently.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  });

  // User taps a notification and it opens the app.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 Notification tapped (app was in background): ${message.data}');
    // Optional: navigate to the admin notifications screen here.
  });

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const _AutoRoute();
          }
          return const SignInScreen();
        },
      ),
    );
  }
}

class _AutoRoute extends StatefulWidget {
  const _AutoRoute();

  @override
  State<_AutoRoute> createState() => _AutoRouteState();
}

class _AutoRouteState extends State<_AutoRoute> {
  @override
  void initState() {
    super.initState();
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