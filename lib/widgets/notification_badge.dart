import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/notification_page.dart'; // ✅ ADD THIS

class NotificationBadge extends StatelessWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: NotificationService().getUnreadCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Badge(
          label: count > 0 ? Text('$count') : null,
          isLabelVisible: count > 0,
          backgroundColor: Colors.red,
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          child: child,
        );
      },
    );
  }
}
