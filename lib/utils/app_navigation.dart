import 'package:flutter/material.dart';

class AppNavigation {
  static Future push(BuildContext context, Widget page) {
    return Navigator.push(
      context,

      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,

        transitionDuration: const Duration(milliseconds: 250),

        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
