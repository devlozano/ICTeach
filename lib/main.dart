import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Official ICTeach Platform Screen Imports
import 'splash.dart';
import 'home_router.dart';
import 'admin_login.dart';
import 'login.dart';
import 'widgets/offline_indicator.dart';
import 'services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeFirebase();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

Future<void> _initializeFirebase() async {
  if (kIsWeb) {
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
    await FirebaseFirestore.instance.enablePersistence(
      const PersistenceSettings(synchronizeTabs: true),
    );
  } else {
    await Firebase.initializeApp();
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
      navigatorKey: NavigationService.navigatorKey, // ✅ Add navigator key
      builder: (context, child) => OfflineIndicator(child: child!),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffF8FAFC),
        pageTransitionsTheme: PageTransitionsTheme(
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
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const HomeRouter(),
                    ),
                  );
                  return;
                }

                if (kIsWeb) {
                  _navKey.currentState?.pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const AdminLoginPage(),
                    ),
                  );
                } else {
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
