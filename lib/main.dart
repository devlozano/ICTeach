import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

// Official ICTeach Platform Screen Imports
import 'splash.dart';
import 'admin_login.dart'; // Web Platform Gateway
import 'login.dart'; // Mobile Platform Gateway (Handles Student, Teacher, Trainer)
// Admin Dashboard (Management & Report Generation)
// Teacher Dashboard (Lessons & Monitoring)
// Student & Trainer Interface (Simulations & Tasks)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web Configuration Setup for the Admin Portal (icteach-free)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDCnNrIz2g2Ovq5XnocJVBVl5S065vOB2g",
        authDomain: "icteach-free.firebaseapp.com",
        projectId: "icteach-free",
        storageBucket: "icteach-free.firebasestorage.app",
        messagingSenderId: "4824580226",
        appId: "1:4824580226:web:e28624a19f13361241f49b",
        measurementId: "G-S77WYVMF0N",
      ),
    );
  } else {
    // Mobile Configuration Setup for Students, Teachers, and Trainers
    // This reads the localized google-services.json configuration file
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICTeach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _AppEntry(),
    );
  }
}

class _AppEntry extends StatelessWidget {
  _AppEntry();

  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(
          builder: (context) {
            return SplashPage(
              onFinished: () {
                // Device Hardware Check Routing Gate (Aligned with Panel Scope)
                if (kIsWeb) {
                  // Web Browser -> Routes exclusively to Admin Management System
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                } else {
                  // Mobile Devices -> Routes to unified Student, Trainer, & Teacher Login
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
