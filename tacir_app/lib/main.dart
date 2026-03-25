import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/calendar_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/notification_provider.dart';
import 'widgets/notification_overlay.dart';

// Handler background — doit être top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📬 Notification background: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr', null);
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'Tacir App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C4DFF)),
          useMaterial3: true,
        ),
        home: const NotificationOverlay(
          // ← wrappez ici
          child: AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().checkAuth();
    _setupFCM();
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demander la permission (important pour iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      debugPrint("📲 FCM TOKEN: $token"); // <-- ton token ici
    } else {
      debugPrint("⚠️ Notifications non autorisées");
    }

    // Écouter les messages foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Notification foreground: ${message.notification?.title}');
    });

    // Écouter les messages quand l’app est ouverte depuis la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification click: ${message.notification?.title}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.isLoggedIn ? CalendarScreen() : LoginScreen();
  }
}
