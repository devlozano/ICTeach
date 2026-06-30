import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Official ICTeach Platform Screen Imports
import 'splash.dart';
import 'home_router.dart';
import 'admin_login.dart'; // Web Platform Gateway
import 'login.dart'; // Mobile Platform Gateway (Handles Student, Teacher, Trainer)
import 'widgets/offline_indicator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeFirebase();
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue even if Firebase fails - the app will show error screens
  }

  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
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

    // Enable persistence for Web
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } else {
    // Mobile Configuration - reads google-services.json
    await Firebase.initializeApp();

    // Enable offline persistence for Mobile
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICTeach',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => OfflineIndicator(child: child!),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF8FAFC),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2B4A),
          primary: const Color(0xFF0B2B4A),
        ),
      ),
      home: const _AppEntry(),
      // ✅ Add routes for easier navigation
      routes: {
        '/home': (context) => const HomeRouter(),
        '/login': (context) => const LoginPage(),
        '/admin-login': (context) => const AdminLoginPage(),
      },
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
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
                // Check if user is already logged in
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  // User is already logged in, navigate to HomeRouter directly
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const HomeRouter(),
                    ),
                  );
                  return;
                }

                // Device Hardware Check Routing Gate
                if (kIsWeb) {
                  // Web -> Admin Management System
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                } else {
                  // Mobile -> Student, Trainer, & Teacher Login
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
