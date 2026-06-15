import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_home.dart';
import 'home.dart';
import 'login.dart';
import 'teacher_home.dart';
import 'trainer_home.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();

        final role = (data?['role'] as String?)?.toLowerCase().trim();

        print("CURRENT USER ROLE: $role");

        switch (role) {
          case 'admin':
            return const AdminHomePage();

          case 'teacher':
            return const TeacherHomePage();

          case 'trainer':
            return const TrainerHomePage();

          case 'student':
          default:
            return const HomePage();
        }
      },
    );
  }
}
