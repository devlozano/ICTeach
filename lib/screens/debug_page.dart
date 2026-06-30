// lib/screens/debug_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../services/migration_service.dart';
import '../models/notification_model.dart';
import '../widgets/test_notification_button.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  final NotificationService _notificationService = NotificationService();
  final MigrationService _migrationService = MigrationService();
  String _log = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('🔧 Debug Tools'),
        backgroundColor: Colors.purple.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _log = ''),
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Notification Button
            const TestNotificationButton(),

            const SizedBox(height: 16),

            // Debug Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🛠️ Debug Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDebugButton(
                      icon: Icons.people_outline,
                      label: 'Fix Missing Students',
                      color: Colors.orange,
                      onPressed: () => _fixMissingStudents(),
                    ),
                    _buildDebugButton(
                      icon: Icons.class_,
                      label: 'Debug All Classes',
                      color: Colors.blue,
                      onPressed: () => _debugAllClasses(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.notifications,
                      label: 'Debug My Notifications',
                      color: Colors.purple,
                      onPressed: () => _debugMyNotifications(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.people,
                      label: 'Debug Students in Class',
                      color: Colors.green,
                      onPressed: () => _showClassSelector(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.delete_sweep,
                      label: 'Clear All Notifications',
                      color: Colors.red,
                      onPressed: () => _clearAllNotifications(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.info,
                      label: 'Check Notification Count',
                      color: Colors.teal,
                      onPressed: () => _checkNotificationCount(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Migration Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔄 Migration Tools',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Migrate students from enrolledStudentIds to students subcollection',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _buildDebugButton(
                      icon: Icons.sync, // Alternative 4 (best)
                      label: 'Migrate All Students',
                      color: Colors.teal,
                      onPressed: () => _migrateAllStudents(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.class_,
                      label: 'Migrate Current Class',
                      color: Colors.indigo,
                      onPressed: () => _migrateCurrentClass(),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      icon: Icons.person_add,
                      label: 'Fix Single Student',
                      color: Colors.cyan,
                      onPressed: () => _fixSingleStudent(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Quick Test Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Quick Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a test notification for the current user',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _createQuickTestNotification(),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Create Test Notification'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Log Output
            if (_log.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '📋 Debug Log',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _log = ''),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _log,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _debugAllClasses() async {
    setState(() => _log = '🔄 Debugging all classes...\n');
    try {
      await _notificationService.debugAllClasses();
      setState(() => _log += '✅ Debug complete! Check console.\n');
      _showSnackBar('✅ Debug complete! Check console.', Colors.green);
    } catch (e) {
      setState(() => _log += '❌ Error: $e\n');
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _debugMyNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _log = '❌ Please login first\n');
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    setState(() => _log = '🔍 Checking notifications for ${user.uid}...\n');
    try {
      await _notificationService.debugUserNotifications(user.uid);
      setState(() => _log += '✅ Check console for details\n');
      _showSnackBar('✅ Check console for details', Colors.green);
    } catch (e) {
      setState(() => _log += '❌ Error: $e\n');
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _checkNotificationCount() async {
    try {
      final count = await _notificationService.getNotificationCount();
      final hasNotif = await _notificationService.hasNotifications();

      setState(() => _log = '📊 Notification Count: $count\n');
      setState(() => _log += '📊 Has Notifications: $hasNotif\n');

      _showSnackBar('📊 You have $count notification(s)', Colors.blue);
    } catch (e) {
      setState(() => _log += '❌ Error: $e\n');
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  Future<void> _showClassSelector() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _log = '❌ Please login first\n');
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      if (classesSnapshot.docs.isEmpty) {
        setState(() => _log = '📊 No classes found for this teacher\n');
        _showSnackBar('No classes found', Colors.orange);
        return;
      }

      final classItems = classesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'name': data['name']?.toString() ?? 'Unnamed',
          'id': doc.id,
        };
      }).toList();

      // Show dialog to select class
      final selectedClass = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select a Class'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: classItems.length,
              itemBuilder: (context, index) {
                final item = classItems[index];
                return ListTile(
                  title: Text(item['name']!),
                  subtitle: Text('ID: ${item['id']}'),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ),
      );

      if (selectedClass != null) {
        setState(() => _log = '🔍 Debugging class: ${selectedClass['name']}\n');
        await _notificationService.debugClassStudents(selectedClass['id']!);
        setState(() => _log += '✅ Check console for details\n');
        _showSnackBar('✅ Debug complete! Check console.', Colors.green);
      }
    } catch (e) {
      setState(() => _log += '❌ Error: $e\n');
      _showSnackBar('❌ Error: $e', Colors.red);
    }
  }

  // ✅ Migration Methods

  // In debug_page.dart, add this button in the Migration Tools section:

// Add this method:
  Future<void> _fixMissingStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fix Missing Students?'),
        content:
            const Text('This will add all students from enrolledStudentIds '
                'that are missing from the students subcollection.\n\n'
                'This will NOT create duplicates. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Fix Missing'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _log = '🔄 Fixing missing students...\n');
      try {
        await _migrationService.migrateMissingStudentsToSubcollection();
        setState(() => _log += '✅ Migration complete! Check console.\n');
        _showSnackBar('✅ Migration complete!', Colors.green);
      } catch (e) {
        setState(() => _log += '❌ Error: $e\n');
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  Future<void> _migrateAllStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate All Students?'),
        content:
            const Text('This will migrate ALL students from enrolledStudentIds '
                'to the students subcollection for ALL classes.\n\n'
                'This will NOT create duplicates. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
            child: const Text('Migrate All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _log = '🔄 Starting migration...\n');
      try {
        await _migrationService.migrateAllStudentsToSubcollection();
        setState(() => _log += '✅ Migration complete! Check console.\n');
        _showSnackBar('✅ Migration complete!', Colors.green);
      } catch (e) {
        setState(() => _log += '❌ Error: $e\n');
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  Future<void> _migrateCurrentClass() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // Get user's current class
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('classes')
        .get();

    if (classesSnapshot.docs.isEmpty) {
      _showSnackBar('You are not in any class', Colors.orange);
      return;
    }

    final classDoc = classesSnapshot.docs.first;
    final classData = classDoc.data();
    final classId = classData['classId'] ?? '';
    final className = classData['className'] ?? 'Unknown';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Migrate Class Students?'),
        content: Text('Migrate students for:\n"$className"?\n\n'
            'This will add all students from enrolledStudentIds '
            'to the students subcollection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.indigo),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _log = '🔄 Migrating class: $className\n');
      try {
        await _migrationService.migrateClassStudents(classId);
        setState(() => _log += '✅ Migration complete! Check console.\n');
        _showSnackBar('✅ Migration complete!', Colors.green);
      } catch (e) {
        setState(() => _log += '❌ Error: $e\n');
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  Future<void> _fixSingleStudent() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // Get user's current class
    final classesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('classes')
        .get();

    if (classesSnapshot.docs.isEmpty) {
      _showSnackBar('You are not in any class', Colors.orange);
      return;
    }

    final classDoc = classesSnapshot.docs.first;
    final classId = classDoc.data()['classId'] ?? '';

    // Show dialog to enter student ID
    final studentIdController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Student to Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the student UID to add to the class:'),
            const SizedBox(height: 12),
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student UID',
                border: OutlineInputBorder(),
                hintText: 'e.g., zmWRwQRRCGelZGuMIcx4jZxzA5S2',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, studentIdController.text.trim()),
            child: const Text('Add Student'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _log = '🔄 Adding student: $result\n');
      try {
        await _migrationService.addStudentToClass(classId, result);
        setState(() => _log += '✅ Student added successfully!\n');
        _showSnackBar('✅ Student added successfully!', Colors.green);
      } catch (e) {
        setState(() => _log += '❌ Error: $e\n');
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    // First check if there are notifications
    final hasNotif = await _notificationService.hasNotifications();
    if (!hasNotif) {
      _showSnackBar('ℹ️ No notifications to delete', Colors.blue);
      setState(() => _log = 'ℹ️ No notifications to delete\n');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
            'This will delete all your notifications. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _log = '🗑️ Clearing all notifications...\n');
      try {
        await _notificationService.deleteAllNotifications();
        setState(() => _log += '✅ All notifications cleared successfully!\n');
        _showSnackBar('✅ All notifications cleared!', Colors.green);
      } catch (e) {
        setState(() => _log += '❌ Error: $e\n');
        _showSnackBar('❌ Error clearing notifications: $e', Colors.red);
      }
    }
  }

  Future<void> _createQuickTestNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login first', Colors.red);
      return;
    }

    try {
      await _notificationService.createNotification(
        NotificationModel(
          id: '',
          userId: user.uid,
          title: '🧪 Quick Test Notification',
          message:
              'This is a test notification created at ${DateTime.now().toLocal().toString().substring(0, 19)}',
          type: 'test',
          referenceId: 'test',
          createdAt: DateTime.now(),
        ),
      );

      _showSnackBar('✅ Test notification created!', Colors.green);
      setState(
          () => _log += '✅ Test notification created at ${DateTime.now()}\n');
    } catch (e) {
      _showSnackBar('❌ Error: $e', Colors.red);
      setState(() => _log += '❌ Error: $e\n');
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
