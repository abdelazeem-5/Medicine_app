import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:medicine_app/services/notification_service.dart';
import 'package:medicine_app/services/theme_service.dart';
import 'package:medicine_app/screens/login.dart';
import 'package:medicine_app/screens/home.dart';
import 'package:medicine_app/screens/add_medicine.dart';
import 'package:medicine_app/screens/history.dart';
import 'package:medicine_app/screens/calendar.dart';
import 'package:medicine_app/screens/settings.dart'; 
import 'package:medicine_app/screens/reports.dart';
import 'package:medicine_app/screens/signup.dart';
import 'package:medicine_app/screens/welcome_page.dart';
import 'package:medicine_app/screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    await NotificationService.init();
    await NotificationService.requestPermission();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  // 🔥 Load saved theme
  Future<void> _loadTheme() async {
    final mode = await ThemeService.getTheme();
    setState(() => _themeMode = mode);
  }

  // 🔥 Change + save theme
  Future<void> changeTheme(ThemeMode mode) async {
    await ThemeService.setTheme(mode);
    setState(() => _themeMode = mode);
  }

  Widget _getStartScreen() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomePage();
        }

        return const WelcomePage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',

      // 🔥 Global theme control
      themeMode: _themeMode,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C7DA0),
        ),
        useMaterial3: true,
        brightness: Brightness.light,
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C7DA0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),

      home: _getStartScreen(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/add': (context) => const AddMedicinePage(),
        '/history': (context) => const HistoryPage(),
        '/calendar': (context) => const CalendarPage(),
        '/settings': (context) => const SettingsPage(), 
        '/reports': (context) => const ReportsPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}