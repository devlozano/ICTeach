// lib/widgets/test_notification_button.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔔 Notification Testing',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use these buttons to test notification functionality',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendTestNotification(context),
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _debugStudents(context),
                    icon: const Icon(Icons.bug_report, size: 18),
                    label: const Text('Debug Students'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(context, 'Please login first', Colors.red);
      return;
    }

    try {
      final notificationService = NotificationService();

      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creating test notification...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create test notification
      await notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: user.uid,
          title: '🧪 Test Notification',
          message:
              'This is a test notification from ICTeach at ${DateTime.now().toLocal()}',
          type: 'test',
          referenceId: 'test',
          createdAt: DateTime.now(),
        ),
      );

      _showSnackBar(
          context,
          '✅ Test notification created successfully! Check your notifications.',
          Colors.green);
    } catch (e) {
      _showSnackBar(context, '❌ Error: $e', Colors.red);
    }
  }

  Future<void> _debugStudents(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar(context, 'Please login first', Colors.red);
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking student data...'),
          duration: Duration(seconds: 1),
        ),
      );

      final notificationService = NotificationService();
      await notificationService.debugAllClasses();

      _showSnackBar(
          context, '✅ Debug completed! Check console logs.', Colors.green);
    } catch (e) {
      _showSnackBar(context, '❌ Error: $e', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
