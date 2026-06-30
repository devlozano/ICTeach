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

      // Check if user is already enrolled
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

      // ✅ Get user role from users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final userRole = userData['role']?.toString() ?? 'student';
      final userName =
          userData['name']?.toString() ?? user.displayName ?? 'User';
      final userEmail = user.email ?? '';

      print('👤 User joining class: $userName');
      print('👤 User role: $userRole');
      print('📚 Class: $className');

      // ✅ STEP 1: Add user to class's students subcollection (for notifications & roster)
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': userName,
        'email': userEmail,
        'role': userRole, // ✅ Store the role (student/trainer)
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      print('✅ Added user to class subcollection with role: $userRole');

      // ✅ STEP 2: Update enrolledStudentIds array in class document
      await classDoc.reference.update({
        'enrolledStudentIds': FieldValue.arrayUnion([user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Updated enrolledStudentIds array');

      // ✅ STEP 3: Store ALL class data in user's subcollection
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
        'teacherName': teacherName,
        'teacherEmail': teacherEmail,
        'schoolYear': schoolYear,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      print('✅ Added class to user\'s subcollection');

      // ✅ STEP 4: Update the user's main document with class info
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
        print('✅ Updated user main document');
      }

      if (!mounted) return;

      // Show success message
      final roleEmoji = userRole == 'trainer' ? '👑' : '🎓';
      final roleLabel = userRole == 'trainer' ? 'Trainer' : 'Student';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '✅ Successfully joined class as $roleLabel!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Class: $className', style: const TextStyle(fontSize: 13)),
              Text(
                'Teacher: $teacherName',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '$roleEmoji Role: $roleLabel',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
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
                        counterText: '', // Hide character counter
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
