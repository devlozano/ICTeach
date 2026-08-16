import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'module_view_page.dart';

class PreAssessmentPage extends StatefulWidget {
  final String classId;
  final String className;

  const PreAssessmentPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<PreAssessmentPage> createState() => _PreAssessmentPageState();
}

class _PreAssessmentPageState extends State<PreAssessmentPage> {
  bool _hasTakenPreAssessment = false;
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role']?.toString() ?? 'student';
      setState(() => _userRole = role);
      await _checkPreAssessment();
    } catch (_) {
      setState(() => _userRole = 'student');
      await _checkPreAssessment();
    }
  }

  Future<void> _checkPreAssessment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (_userRole == 'trainer' || _userRole == 'teacher') {
      setState(() {
        _hasTakenPreAssessment = true;
        _isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('pre_assessments')
          .doc('${user.uid}_${widget.classId}')
          .get();

      setState(() {
        _hasTakenPreAssessment = doc.exists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildModulesContent() {
    return ModuleViewPage(
      classId: widget.classId,
      className: widget.className,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasTakenPreAssessment ||
        _userRole == 'trainer' ||
        _userRole == 'teacher') {
      return _buildModulesContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Pre-Assessment - ${widget.className}'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Pre-Assessment Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete the pre-assessment before accessing modules.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Complete pre-assessment logic or navigate to assessment quiz
                FirebaseFirestore.instance
                    .collection('pre_assessments')
                    .doc(
                        '${FirebaseAuth.instance.currentUser?.uid}_${widget.classId}')
                    .set({
                  'completedAt': FieldValue.serverTimestamp(),
                  'classId': widget.classId,
                  'studentId': FirebaseAuth.instance.currentUser?.uid,
                });

                setState(() {
                  _hasTakenPreAssessment = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B2B4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Start Pre-Assessment'),
            ),
          ],
        ),
      ),
    );
  }
}
