import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔥 مهم
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:medicine_app/services/notification_service.dart';

import 'package:medicine_app/screens/login.dart';
import 'package:medicine_app/screens/home.dart';
import 'package:medicine_app/screens/add_medicine.dart';
import 'package:medicine_app/screens/history.dart';
import 'package:medicine_app/screens/calendar.dart';
import 'package:medicine_app/screens/notifications.dart';
import 'package:medicine_app/screens/reports.dart';
import 'package:medicine_app/screens/integration.dart';
import 'package:medicine_app/screens/ring_tones.dart';
import 'package:medicine_app/screens/signup.dart';
import 'package:medicine_app/screens/landing_page.dart';
import 'package:medicine_app/screens/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔥 تشغيل الإشعارات فقط على الموبايل
  if (!kIsWeb) {
    await NotificationService.init();
    await NotificationService.requestPermission();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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

        return const LandingPage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),

      home: _getStartScreen(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/add': (context) => const AddMedicinePage(),
        '/history': (context) => const HistoryPage(),
        '/calendar': (context) => const CalendarPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/reports': (context) => const ReportsPage(),
        '/integration': (context) => const IntegrationPage(),
        '/ringtones': (context) => const RingTonesPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}