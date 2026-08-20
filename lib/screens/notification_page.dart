// screens/notification_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../screens/student/student_quizzes_page.dart';
import '../screens/student/student_assignments_page.dart';
import '../screens/student/module_view_page.dart';
import '../screens/student/forums_page.dart';
import '../screens/teacher/manage_quizzes_page.dart';
import '../screens/teacher/manage_assignments_page.dart';
import '../screens/teacher/manage_modules_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _userRole = data?['role']?.toString() ?? 'student';
          });
        }
      } catch (e) {
        print('Error getting user role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
                onDismiss: () => _deleteNotification(notification.id),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read
    await _notificationService.markAsRead(notification.id);

    // ✅ Get the class ID from the notification's referenceId
    final classId = notification.referenceId;

    if (classId == null || classId.isEmpty) {
      _showErrorSnackbar('Class information not available');
      return;
    }

    // ✅ Get class name from the class document
    String className = 'Class';
    try {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();
      if (classDoc.exists) {
        final data = classDoc.data();
        className =
            data?['name']?.toString() ??
            data?['className']?.toString() ??
            'Class';
      }
    } catch (e) {
      print('Error getting class name: $e');
    }

    // Navigate based on notification type and user role
    switch (notification.type) {
      case 'quiz':
        _navigateToQuiz(context, notification, classId, className);
        break;
      case 'assignment':
        _navigateToAssignment(context, notification, classId, className);
        break;
      case 'forum':
        _navigateToForum(context, notification, classId, className);
        break;
      case 'module':
        _navigateToModule(context, notification, classId, className);
        break;
      case 'grade':
        _navigateToGrade(context, notification);
        break;
      default:
        Navigator.pop(context);
    }
  }

  void _navigateToQuiz(
    BuildContext context,
    NotificationModel notification,
    String classId,
    String className,
  ) {
    // Close notification page
    Navigator.pop(context);

    // Navigate based on user role
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_userRole == 'teacher' || _userRole == 'trainer') {
        // Teacher/Trainer: Go to manage quizzes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ManageQuizzesPage(classId: classId, className: className),
          ),
        );
      } else {
        // Student: Go to take quizzes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentQuizzesPage(classId: classId, className: className),
          ),
        );
      }
    });
  }

  void _navigateToAssignment(
    BuildContext context,
    NotificationModel notification,
    String classId,
    String className,
  ) {
    // Close notification page
    Navigator.pop(context);

    // Navigate based on user role
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_userRole == 'teacher' || _userRole == 'trainer') {
        // Teacher/Trainer: Go to manage assignments
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ManageAssignmentsPage(classId: classId, className: className),
          ),
        );
      } else {
        // Student: Go to view assignments
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentAssignmentsPage(classId: classId, className: className),
          ),
        );
      }
    });
  }

  void _navigateToForum(
    BuildContext context,
    NotificationModel notification,
    String classId,
    String className,
  ) {
    // Close notification page
    Navigator.pop(context);

    // ✅ Navigate to forums for all roles
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ForumsPage(classId: classId, className: className),
        ),
      );
    });
  }

  void _navigateToModule(
    BuildContext context,
    NotificationModel notification,
    String classId,
    String className,
  ) {
    // Close notification page
    Navigator.pop(context);

    // Navigate based on user role
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_userRole == 'teacher' || _userRole == 'trainer') {
        // Teacher/Trainer: Go to manage modules
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ManageModulesPage(classId: classId, className: className),
          ),
        );
      } else {
        // Student: Go to view modules
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ModuleViewPage(classId: classId, className: className),
          ),
        );
      }
    });
  }

  void _navigateToGrade(BuildContext context, NotificationModel notification) {
    // Close notification page
    Navigator.pop(context);

    // Show grade dialog
    Future.delayed(const Duration(milliseconds: 100), () {
      _showGradeDialog(context, notification);
    });
  }

  void _showGradeDialog(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Grade Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(notification.message),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Check your grades in the Progress tab',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteNotification(String id) async {
    await _notificationService.deleteNotification(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// Notification Card Widget
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(notification.type);
    final color = _getColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      onDismissed: (_) => onDismiss(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : Colors.blue.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w600
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTypeColor(
                              notification.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(notification.type),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'assignment':
        return Icons.assignment_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'grade':
        return Icons.grade_rounded;
      case 'forum':
        return Icons.forum_rounded;
      case 'module':
        return Icons.menu_book_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.orange;
      case 'quiz':
        return Colors.purple;
      case 'grade':
        return Colors.green;
      case 'forum':
        return Colors.blue;
      case 'module':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    return _getColor(type);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'assignment':
        return 'Assignment';
      case 'quiz':
        return 'Quiz';
      case 'grade':
        return 'Grade';
      case 'forum':
        return 'Forum';
      case 'module':
        return 'Module';
      default:
        return 'General';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
