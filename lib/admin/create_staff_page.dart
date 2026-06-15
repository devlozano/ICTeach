import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:icteach/emailjs_service.dart';

class CreateStaffPage extends StatefulWidget {
  final String selectedRole;

  const CreateStaffPage({super.key, required this.selectedRole});

  @override
  State<CreateStaffPage> createState() => _CreateStaffPageState();
}

class _CreateStaffPageState extends State<CreateStaffPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();
  final _emailController = TextEditingController();

  late String _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.selectedRole;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String getMiddleInitial(String middleName) {
    return middleName.trim().isEmpty
        ? ''
        : '${middleName.trim()[0].toUpperCase()}.';
  }

  String generatePassword() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();

    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
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

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<UserCredential> createStaffAccount({
    required String email,
    required String password,
  }) async {
    return await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> _createStaff() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tempPassword = generatePassword();

      if (tempPassword.length < 6) {
        throw Exception("Password too short for Firebase");
      }

      final first = _firstNameController.text.trim();
      final middle = _middleNameController.text.trim();
      final last = _lastNameController.text.trim();
      final ext = _extensionController.text.trim();
      final email = _emailController.text.trim();

      if (email.isEmpty || !email.contains('@')) {
        throw Exception("Invalid email address");
      }

      final middleInitial = getMiddleInitial(middle);

      final displayName = [
        first,
        middleInitial,
        last,
        ext,
      ].where((e) => e.isNotEmpty).join(' ');

      final credential = await createStaffAccount(
        email: email,
        password: tempPassword,
      );

      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': first,
        'middleName': middle,
        'middleInitial': middleInitial,
        'lastName': last,
        'extension': ext,
        'name': displayName,
        'email': email,
        'role': _selectedRole,
        'mustChangePassword': true,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await EmailJSService.sendStaffCredentials(
        email: email,
        name: displayName,
        role: _selectedRole.toUpperCase(),
        password: tempPassword,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Staff Created'),
          content: Text(
            'Account created for ${_selectedRole.toUpperCase()}\n\n'
            'Temporary password:\n$tempPassword\n\n'
            'Credentials sent to email.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
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
        SnackBar(content: Text(e.message ?? 'Auth error occurred')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _middleNameController,
                decoration: fieldDecoration(
                  hint: 'Middle Name',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: fieldDecoration(
                  hint: 'Last Name',
                  icon: Icons.person_outline,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _extensionController,
                decoration: fieldDecoration(
                  hint: 'Extension (Jr., Sr., III)',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: fieldDecoration(
                  hint: 'Email Address',
                  icon: Icons.email,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: fieldDecoration(hint: 'Role', icon: Icons.badge),
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'trainer', child: Text('Trainer')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRole = v);
                },
              ),
              const SizedBox(height: 20),
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
