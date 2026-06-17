import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math'; // ✅ Add this for random generation

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // ✅ NEW: Generate a unique class code (like Google Classroom)
  String _generateClassCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random random = Random();
    String code = '';

    // Generate a 7-character code (e.g., "ABC1234")
    for (int i = 0; i < 7; i++) {
      code += chars[random.nextInt(chars.length)];
    }

    return code;
  }

  // ✅ NEW: Check if class code already exists
  Future<bool> _isClassCodeUnique(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('classes')
        .where('classCode', isEqualTo: code)
        .get();

    return query.docs.isEmpty;
  }

  // ✅ NEW: Generate unique class code (retry if duplicate)
  Future<String> _generateUniqueClassCode() async {
    String code;
    bool isUnique;

    do {
      code = _generateClassCode();
      isUnique = await _isClassCodeUnique(code);
    } while (!isUnique);

    return code;
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final teacher = FirebaseAuth.instance.currentUser;
    if (teacher == null) {
      _showMessage("No teacher account found.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get trimmed values
      final className = _classNameController.text.trim();
      final sectionCode = _sectionController.text.trim();
      final description = _descriptionController.text.trim();

      // Check duplicate class
      final existing = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacher.uid)
          .where('name', isEqualTo: className)
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage("You already created this class.");
        return;
      }

      // ✅ NEW: Generate unique class code
      final classCode = await _generateUniqueClassCode();

      final classRef = FirebaseFirestore.instance.collection('classes').doc();

      // Safely get teacher name - ensure it's never null
      String teacherName = "Unknown Teacher";
      if (teacher.displayName != null && teacher.displayName!.isNotEmpty) {
        teacherName = teacher.displayName!;
      } else if (teacher.email != null && teacher.email!.isNotEmpty) {
        teacherName = teacher.email!;
      }

      // Safely get teacher email - ensure it's never null
      String teacherEmail = teacher.email ?? "No email provided";

      // Create class data with ALL non-nullable strings
      final classData = {
        "id": classRef.id,
        "classCode":
            classCode, // ✅ NEW: Auto-generated code for students to join
        "name": className,
        "description": description,
        "sectionCode": sectionCode,
        "teacherId": teacher.uid,
        "teacherName": teacherName,
        "teacherEmail": teacherEmail,
        "enrolledStudentIds": [],
        "pendingReviews": 0,
        "status": "active",
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // Debug: print the data to see if anything is null
      print("Creating class with data: $classData");

      await classRef.set(classData);

      if (!mounted) return;

      // ✅ MODIFIED: Show success message with the class code
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("✅ Class created successfully!"),
              const SizedBox(height: 4),
              Text(
                "Class Code: $classCode",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text("Share this code with your students to join."),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      print("Error creating class: $error");
      _showMessage("Failed to create class: $error");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text("Create Class"),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create New Class",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ✅ NEW: Amber info box about class code
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
                                "A unique class code will be generated automatically. Share it with your students to join.",
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
                      TextFormField(
                        controller: _classNameController,
                        decoration: const InputDecoration(
                          labelText: "Class Name",
                          hintText: "Example: Computer Systems Servicing",
                          prefixIcon: Icon(Icons.class_),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Class name is required.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: "Section",
                          hintText: "Example: Grade 12 ICT A",
                          prefixIcon: Icon(Icons.groups),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Description (optional)",
                          hintText: "Brief description of the class",
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createClass,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B2B4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                              : const Text("Create Class"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
