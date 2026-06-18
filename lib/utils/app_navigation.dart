import 'package:flutter/material.dart';

class AppNavigation {
  static Future push(BuildContext context, Widget page) {
    return Navigator.push(
      context,

      PageRouteBuilder(
        pageBuilder: (_, _, _) => page,

        transitionDuration: const Duration(milliseconds: 250),

        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
