// lib/screens/debug_migration_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DebugMigrationPage extends StatefulWidget {
  const DebugMigrationPage({super.key});

  @override
  State<DebugMigrationPage> createState() => _DebugMigrationPageState();
}

class _DebugMigrationPageState extends State<DebugMigrationPage> {
  bool _isLoading = false;
  String _log = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Migration Tool'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'This will migrate all users from "students" collection to "users" collection',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Text(
                '⚠️ Run this only once! It will create user documents for all students.',
                style:
                    TextStyle(color: Colors.amber, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _migrateExistingUsers,
              icon: const Icon(
                  Icons.sync), // ✅ Fixed: Changed from Icons.migration
              label: const Text('Run Migration'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_log.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _log,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _migrateExistingUsers() async {
    setState(() {
      _isLoading = true;
      _log = '🔄 Starting migration...\n';
    });

    try {
      // Get all students from students collection
      final studentsSnapshot =
          await FirebaseFirestore.instance.collection('students').get();

      setState(
          () => _log += '📊 Found ${studentsSnapshot.docs.length} students\n');

      int migratedCount = 0;
      int skippedCount = 0;

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? doc.id;

        // Check if user exists in users collection
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          // Copy data to users collection
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'name': data['name'] ?? data['displayName'] ?? 'Student',
            'displayName': data['displayName'] ?? data['name'] ?? 'Student',
            'email': data['email'] ?? '',
            'role': data['role'] ?? 'student',
            'firstName': data['firstName'] ?? '',
            'middleName': data['middleName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'extension': data['extension'] ?? '',
            'migratedAt': FieldValue.serverTimestamp(),
          });
          migratedCount++;
          setState(() => _log += '✅ Migrated user: $uid\n');
        } else {
          skippedCount++;
          setState(() => _log += '⏭️ Skipped user: $uid (already exists)\n');
        }
      }

      setState(() => _log += '\n✅ Migration complete!\n');
      setState(() =>
          _log += '📊 Migrated: $migratedCount, Skipped: $skippedCount\n');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Migration complete! Migrated: $migratedCount users'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      setState(() => _log += '❌ Migration error: $e\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Migration error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
