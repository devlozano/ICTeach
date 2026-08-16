import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/content_lock_model.dart';

class ContentLockManager extends StatefulWidget {
  final String classId;

  const ContentLockManager({super.key, required this.classId});

  @override
  State<ContentLockManager> createState() => _ContentLockManagerState();
}

class _ContentLockManagerState extends State<ContentLockManager> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content Access'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('content_locks')
            .where('classId', isEqualTo: widget.classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final locks = snapshot.data!.docs.map((doc) {
            return ContentLock.fromFirestore(doc);
          }).toList();

          if (locks.isEmpty) {
            return const Center(
              child: Text(
                'No content locks configured for this class.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: locks.length,
            itemBuilder: (context, index) {
              final lock = locks[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: SwitchListTile(
                  title: Text(lock.contentType.toUpperCase()),
                  subtitle: Text('ID: ${lock.contentId}'),
                  value: !lock.isLocked,
                  onChanged: (value) {
                    _toggleLock(lock, !value);
                  },
                  secondary: Icon(
                    lock.isLocked ? Icons.lock : Icons.lock_open,
                    color: lock.isLocked ? Colors.red : Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleLock(ContentLock lock, bool newState) async {
    await FirebaseFirestore.instance
        .collection('content_locks')
        .doc(lock.id)
        .update({
      'isLocked': newState,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
