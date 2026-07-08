import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'home_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _extensionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // List of values that should be treated as "no extension"
  static const List<String> _noExtensionValues = [
    'none',
    'n/a',
    'na',
    'n.a',
    'n.a.',
    'none',
    'NONE',
    'None',
    'N/A',
    'n/a',
    'null',
    'NULL',
    'Null',
    'no',
    'NO',
    'No',
    '0',
    'zero',
    'ZERO',
    'none.',
    'NONE.',
    'None.',
    'na',
    'NA',
    'Na',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _extensionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to clean extension value
  String _cleanExtension(String value) {
    final trimmed = value.trim();

    // Check if the value is in the "no extension" list
    if (_noExtensionValues.contains(trimmed.toLowerCase())) {
      return '';
    }

    // Check if it's just special characters
    if (RegExp(r'^[^a-zA-Z]+$').hasMatch(trimmed)) {
      return '';
    }

    // Check if it's just numbers
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return '';
    }

    // Check if it's a single letter that's not a valid suffix
    if (trimmed.length == 1 &&
        !['J', 'S', 'R', 'V', 'X', 'Z'].contains(trimmed.toUpperCase())) {
      return '';
    }

    // If it's a valid extension, capitalize it properly
    return _capitalizeExtension(trimmed);
  }

  // Function to properly format extension
  String _capitalizeExtension(String value) {
    // Common suffix patterns
    final suffixes = {
      'jr': 'Jr.',
      'jr.': 'Jr.',
      'sr': 'Sr.',
      'sr.': 'Sr.',
      'i': 'I',
      'ii': 'II',
      'iii': 'III',
      'iv': 'IV',
      'v': 'V',
      'vi': 'VI',
      'vii': 'VII',
      'viii': 'VIII',
      'ix': 'IX',
      'x': 'X',
    };

    final lower = value.toLowerCase();
    if (suffixes.containsKey(lower)) {
      return suffixes[lower]!;
    }

    // If it's already properly formatted (e.g., "Jr.", "Sr.", "III")
    if (RegExp(r'^(Jr\.|Sr\.|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII)$')
        .hasMatch(value)) {
      return value;
    }

    // Default: capitalize first letter
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  // Validate extension
  String? _validateExtension(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Extension is optional
    }

    final cleaned = _cleanExtension(value);
    if (cleaned.isEmpty) {
      return null; // Treat as empty if cleaned is empty
    }

    // Check if it's a valid suffix format
    final validPatterns = [
      r'^(Jr\.|Sr\.|I|II|III|IV|V|VI|VII|VIII|IX|X|XI|XII|XIII|XIV|XV)$',
      r'^[A-Z][a-z]?\.?$', // Single letter with optional period
      r'^[A-Z]{2,3}$', // Multiple letters
    ];

    for (final pattern in validPatterns) {
      if (RegExp(pattern).hasMatch(cleaned)) {
        return null; // Valid
      }
    }

    return 'Please enter a valid suffix (e.g., Jr., Sr., III) or leave blank.';
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'missing-user',
          message: 'Account was created, but user data was not returned.',
        );
      }

      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      // Clean extension before saving
      final extensionRaw = _extensionController.text.trim();
      final extension = _cleanExtension(extensionRaw);

      final displayName = _displayName(
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        extension: extension,
      );

      await user.updateDisplayName(displayName);
      final profileSaved = await _saveStudentProfile(
        uid: user.uid,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        extension: extension,
        displayName: displayName,
      );

      if (!mounted) return;

      if (profileSaved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created, but profile was not saved.'),
          ),
        );
      }
      _openHome();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      _showError(_authErrorMessage(error));
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showError(_firebaseErrorMessage(error));
    } catch (error) {
      if (!mounted) return;

      _showError('Could not create account: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email registration is not enabled.';
      case 'configuration-not-found':
        return 'Firebase Auth is not configured. Enable Email/Password sign-in in Firebase Console.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'missing-user':
        return error.message ?? 'Account could not be completed.';
      default:
        return '${error.code}: ${error.message ?? 'Please try again.'}';
    }
  }

  String _firebaseErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Account created, but Firestore rules blocked saving the profile.';
      case 'unavailable':
        return 'Firebase is unavailable right now. Please try again.';
      default:
        return '${error.plugin}/${error.code}: ${error.message ?? 'Please try again.'}';
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _displayName({
    required String firstName,
    required String middleName,
    required String lastName,
    required String extension,
  }) {
    final names = [
      firstName,
      if (middleName.isNotEmpty) middleName,
      lastName,
      if (extension.isNotEmpty) extension,
    ];

    return names.join(' ');
  }

  void _openHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeRouter()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2F80ED);
    const inputBorder = Color(0xFFC7D3EA);
    const registerGreen = Color(0xFF12A150);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final horizontalPadding = width >= 600 ? 48.0 : 22.0;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                _RegisterHeader(availableWidth: width),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            24,
                            horizontalPadding,
                            24,
                          ),
                          child: _buildForm(inputBorder, registerGreen),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(Color inputBorder, Color registerGreen) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join ICTeach and start learning',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.black.withValues(alpha: 0.56),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          _LabeledField(
            label: 'First Name',
            child: TextFormField(
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.givenName],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'First name is required.';
                }
                if (value.trim().length < 2) {
                  return 'Enter your first name.';
                }
                return null;
              },
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Juan',
                icon: Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Middle Name',
            child: TextFormField(
              controller: _middleNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.middleName],
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Santos',
                icon: Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Last Name',
            child: TextFormField(
              controller: _lastNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.familyName],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Last name is required.';
                }
                if (value.trim().length < 2) {
                  return 'Enter your last name.';
                }
                return null;
              },
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Dela Cruz',
                icon: Icons.person_outline_rounded,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Extension (Optional)',
            child: TextFormField(
              controller: _extensionController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Jr., Sr., III',
                icon: Icons.person_add_alt_1_outlined,
              ),
              validator: _validateExtension,
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Email Address',
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Email address is required.';
                }
                if (!_isValidEmail(email)) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'student@school.edu.ph',
                icon: Icons.email_outlined,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Password',
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Create a password',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _LabeledField(
            label: 'Confirm Password',
            child: TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _isLoading ? null : _register(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password.';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
              decoration: _fieldDecoration(
                borderColor: inputBorder,
                hintText: 'Re-enter your password',
                icon: Icons.verified_user_outlined,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                  onPressed: () {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  tooltip: _obscureConfirmPassword
                      ? 'Show password'
                      : 'Hide password',
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: registerGreen,
                disabledBackgroundColor: registerGreen.withValues(alpha: 0.55),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.6,
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('Already have an account? Sign In'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required Color borderColor,
    required String hintText,
    required IconData icon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor, width: 2),
    );

    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF4D89FF)),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF2F80ED), width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFFE5484D), width: 2),
      ),
    );
  }

  Future<bool> _saveStudentProfile({
    required String uid,
    required String firstName,
    required String middleName,
    required String lastName,
    required String extension,
    required String displayName,
  }) async {
    final data = <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'extension': extension,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('students').doc(uid).set(data);
    return true;
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.availableWidth});

  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final logoSize = (availableWidth * 0.22).clamp(82.0, 126.0);
    final titleSize = (availableWidth * 0.082).clamp(31.0, 42.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Image.asset(
            'assets/logo 2.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: logoSize,
                height: logoSize,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF2F80ED),
                  size: 50,
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'ICTeach',
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'TVL-ICT Learning Management System',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: availableWidth >= 600 ? 16 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
