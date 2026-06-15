import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class CreateStaffPage extends StatefulWidget {
  final String selectedRole;

  const CreateStaffPage({super.key, required this.selectedRole});

  @override
  State<CreateStaffPage> createState() => _CreateStaffPageState();
}

class _CreateStaffPageState extends State<CreateStaffPage> {
  @override
  void initState() {
    super.initState();

    _selectedRole = widget.selectedRole;
  }

  String getMiddleInitial(String middleName) {
    if (middleName.trim().isEmpty) {
      return '';
    }

    return '${middleName.trim()[0].toUpperCase()}.';
  }

  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  late String _selectedRole;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  // Generates temporary password
  String generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    final random = Random();

    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Creates staff account without logging out Admin
  Future<UserCredential> createStaffAccount({
    required String email,
    required String password,
  }) async {
    FirebaseApp secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'StaffCreationApp',
        options: Firebase.app().options,
      );
    } catch (e) {
      secondaryApp = Firebase.app('StaffCreationApp');
    }

    FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

    final credential = await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await secondaryApp.delete();

    return credential;
  }

  Future<void> _createStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tempPassword = generatePassword();
      final middleName = _middleNameController.text.trim();
      final middleInitial = getMiddleInitial(middleName);
      final extensionText = _extensionController.text.trim();
      final displayName = [
        _firstNameController.text.trim(),
        middleInitial,
        _lastNameController.text.trim(),
        extensionText,
      ].where((part) => part.isNotEmpty).join(' ');

      // CREATE AUTH ACCOUNT
      final credential = await createStaffAccount(
        email: _emailController.text.trim(),
        password: tempPassword,
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': _firstNameController.text.trim(),
        'middleName': middleName,
        'middleInitial': middleInitial,
        'lastName': _lastNameController.text.trim(),
        'extension': extensionText,
        'name': displayName,
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'mustChangePassword': true,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // SEND RESET EMAIL
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Staff Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_selectedRole.toUpperCase()} account created successfully.',
              ),
              const SizedBox(height: 15),
              Text(
                'Temporary Password:\n$tempPassword',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const Text(
                'A password reset email has been sent.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _firstNameController.clear();
                _middleNameController.clear();
                _lastNameController.clear();
                _extensionController.clear();
                _emailController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to create account.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Staff Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: fieldDecoration(
                  hint: 'First Name',
                  icon: Icons.person,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _middleNameController,
                decoration: fieldDecoration(
                  hint: 'Middle Name',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: fieldDecoration(
                  hint: 'Last Name',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _extensionController,
                decoration: fieldDecoration(
                  hint: 'Extension (Jr., Sr., III)',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: fieldDecoration(
                  hint: 'Email Address',
                  icon: Icons.email,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: fieldDecoration(hint: 'Role', icon: Icons.badge),
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'trainer', child: Text('Trainer')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createStaff,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Staff Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
