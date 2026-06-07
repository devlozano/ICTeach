import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Needed for platform checking
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Your screen imports
import 'splash.dart';
import 'login.dart'; // Mobile Entry (Student, Trainer, Teacher)
import 'admin_login.dart'; // Web Entry Only
import 'admin_home.dart';
import 'teacher_home.dart';
import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web Configuration Setup mapped to your icteach-free credentials
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDCnNrIz2g2Ovq5XnocJVBVl5S065vOB2g",
        authDomain: "icteach-free.firebaseapp.com",
        projectId: "icteach-free",
        storageBucket: "icteach-free.firebasestorage.app",
        messagingSenderId: "4824580226",
        appId: "1:4824580226:web:e28624a19f13361241f49b",
        measurementId: "G-S77WYVMF0N", // Included your measurement id tracking
      ),
    );
  } else {
    // Mobile Configuration Setup (Reads google-services.json natively)
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
  _AppEntry(); // Removed const because _navKey is not a compile-time constant

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
                // Device Hardware Check Routing Gate
                if (kIsWeb) {
                  // Direct to Admin Web Interface
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                } else {
                  // Direct to Mobile App Interface
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
