import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinClassPage extends StatefulWidget {
  const JoinClassPage({super.key});

  @override
  State<JoinClassPage> createState() => _JoinClassPageState();
}

class _JoinClassPageState extends State<JoinClassPage> {
  final TextEditingController _classCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _classCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinClass() async {
    final classCode = _classCodeController.text.trim().toUpperCase();

    if (classCode.isEmpty) {
      _showMessage("Please enter a class code.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage("Please sign in first.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find class with the given code
      final query = await FirebaseFirestore.instance
          .collection('classes')
          .where('classCode', isEqualTo: classCode)
          .where('status', isEqualTo: 'active')
          .get();

      if (query.docs.isEmpty) {
        _showMessage("No class found with code: $classCode");
        return;
      }

      final classDoc = query.docs.first;
      final classData = classDoc.data();
      final classId = classDoc.id;

      // Check if student is already enrolled
      final enrolledStudents = List<String>.from(
        classData['enrolledStudentIds'] ?? [],
      );
      if (enrolledStudents.contains(user.uid)) {
        _showMessage("You are already enrolled in this class.");
        return;
      }

      // Check if user already has a class (1 student = 1 class)
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

      // ✅ Get teacher name from class data
      final teacherName =
          classData['teacherName']?.toString() ?? 'Unknown Teacher';
      final className = classData['name']?.toString() ?? 'Unnamed Class';
      final description = classData['description']?.toString() ?? '';
      final sectionCode = classData['sectionCode']?.toString() ?? '';
      final classCodeValue = classData['classCode']?.toString() ?? '';
      final teacherId = classData['teacherId']?.toString() ?? '';
      final teacherEmail = classData['teacherEmail']?.toString() ?? '';
      final schoolYear = classData['schoolYear']?.toString() ?? '';

      // Add student to class
      await classDoc.reference.update({
        'enrolledStudentIds': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Store ALL class data in student's subcollection with proper teacher name
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('classes')
          .doc(classId)
          .set({
            'classId': classId,
            'className': className,
            'description': description,
            'sectionCode': sectionCode,
            'classCode': classCodeValue,
            'teacherId': teacherId,
            'teacherName':
                teacherName, // ✅ Now using the proper teacher name from class data
            'teacherEmail': teacherEmail,
            'schoolYear': schoolYear,
            'joinedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

      // ✅ Also update the user's main document with class info if needed
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'currentClassId': classId,
              'currentClassName': className,
              'currentTeacherName': teacherName,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '✅ Successfully joined class!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Class: $className', style: const TextStyle(fontSize: 13)),
              Text(
                'Teacher: $teacherName',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      print("❌ Error joining class: $error");
      _showMessage("Failed to join class: $error");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Join Class"),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      "Join a Class",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B2B4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the class code provided by your teacher",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Enter the 7-character class code. You can only join one class at a time.",
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Class Code Input
                    TextFormField(
                      controller: _classCodeController,
                      decoration: InputDecoration(
                        labelText: "Class Code",
                        hintText: "Enter 7-character code (e.g., ABC1234)",
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF0B2B4A),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 7,
                      onChanged: (value) {
                        // Auto-uppercase
                        if (value != value.toUpperCase()) {
                          _classCodeController.value = TextEditingValue(
                            text: value.toUpperCase(),
                            selection: TextSelection.collapsed(
                              offset: value.length,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Join Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _joinClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B2B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Join Class",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
