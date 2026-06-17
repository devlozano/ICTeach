import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController _codeController = TextEditingController();

  bool _isJoining = false;

  Future<void> _joinClass() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage("Enter class code first");
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Check if student already has a class
      final existingClasses = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('classes')
          .get();

      if (existingClasses.docs.isNotEmpty) {
        _showMessage(
          "You are already enrolled in a class. You can only join one class.",
        );
        return;
      }

      // Find class using class code
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .where('classCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showMessage("Class not found");
        return;
      }

      final classDoc = query.docs.first;

      final classData = classDoc.data();

      // Add student to class members
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classDoc.id)
          .collection('students')
          .doc(user.uid)
          .set({
            'studentId': user.uid,
            'joinedAt': FieldValue.serverTimestamp(),
          });

      // Save class reference inside student account
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('classes')
          .doc(classDoc.id)
          .set({
            'classId': classDoc.id,
            'className': classData['className'],
            'teacherId': classData['teacherId'],
            'joinedAt': FieldValue.serverTimestamp(),
          });

      _showMessage("Successfully joined ${classData['className']}");

      _codeController.clear();
    } catch (e) {
      _showMessage("Error joining class: $e");
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),

      appBar: AppBar(
        title: const Text(
          "Join Class",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF428DEB),
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Enter Class Code",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 10),

            const Text(
              "Ask your teacher for the class code to join.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: _codeController,

              textCapitalization: TextCapitalization.characters,

              decoration: InputDecoration(
                hintText: "Example: ICT123",

                prefixIcon: const Icon(Icons.class_outlined),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),

                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              height: 55,

              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinClass,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0868D8),

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                child: _isJoining
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Join Class",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
