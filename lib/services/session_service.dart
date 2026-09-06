import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const rememberKey = 'icteach_remember_me';
  static Future<void> initialize() async {
    // Native Firebase persists sessions by default. Apply the user's preference
    // at cold start, before the splash screen inspects currentUser.
    if (!kIsWeb &&
        (await SharedPreferences.getInstance()).getBool(rememberKey) == false) {
      await FirebaseAuth.instance.signOut();
    }
  }

  static Future<bool> remembersUser() async =>
      (await SharedPreferences.getInstance()).getBool(rememberKey) ?? true;
  static Future<void> configure(bool remember) async {
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(
        remember ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
    final saved = await (await SharedPreferences.getInstance()).setBool(
      rememberKey,
      remember,
    );
    if (!saved) throw StateError('Unable to save login preference.');
  }
}
