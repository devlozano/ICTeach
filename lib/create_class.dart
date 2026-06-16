import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final teacher = FirebaseAuth.instance.currentUser;

    if (teacher == null) {
      _showMessage("No teacher account found.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check duplicate class
      final existing = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: teacher.uid)
          .where('name', isEqualTo: _classNameController.text.trim())
          .get();

      if (existing.docs.isNotEmpty) {
        _showMessage("You already created this class.");

        return;
      }

      final classRef = FirebaseFirestore.instance.collection('classes').doc();

      await classRef.set({
        "id": classRef.id,

        "name": _classNameController.text.trim(),

        "description": _descriptionController.text.trim(),

        "sectionCode": _sectionController.text.trim(),

        "teacherId": teacher.uid,

        "teacherName": teacher.email,

        "enrolledStudentIds": [],

        "pendingReviews": 0,

        "status": "active",

        "createdAt": FieldValue.serverTimestamp(),

        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Class created successfully.")),
      );

      Navigator.pop(context, true);
    } catch (error) {
      _showMessage("Failed to create class: $error");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Section is required.";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,

                        maxLines: 4,

                        decoration: const InputDecoration(
                          labelText: "Description",

                          hintText: "Class description",

                          prefixIcon: Icon(Icons.description),

                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,

                        height: 50,

                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createClass,

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF12A150),

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,

                                  width: 20,

                                  child: CircularProgressIndicator(
                                    color: Colors.white,

                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Create Class",

                                  style: TextStyle(
                                    fontSize: 17,

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
      ),
    );
  }
}
