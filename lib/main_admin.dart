import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'admin_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Explicitly passing your Firebase web credentials configuration mappings
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDCnNrIz2g2Ovq5XnocJVBVl5S065vOB2g",
      authDomain: "icteach-free.firebaseapp.com",
      projectId: "icteach-free",
      storageBucket: "icteach-free.firebasestorage.app",
      messagingSenderId: "4824580226",
      appId: "1:4824580226:web:9548570b5c52198941f49b",
      measurementId: "G-FGF6G9BQT8",
    ),
  );

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICTeach Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0B2B4A),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      ),
      home: const AdminLoginPage(),
    );
  }
}
