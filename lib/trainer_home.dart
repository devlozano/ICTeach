import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TrainerHomePage extends StatefulWidget {
  const TrainerHomePage({super.key});

  @override
  State<TrainerHomePage> createState() => _TrainerHomePageState();
}

class _TrainerHomePageState extends State<TrainerHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.purple.shade900;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No authenticated user found.')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data?.data();
        final trainerName = _trainerName(profile, user);

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            title: const Text(
              "ICTEACH",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BANNER (Matches Android Compact - 4.png Layout Structure)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 30,
                    top: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back,",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 4),

                      // DYNAMIC TRAINER NAME DISPLAY
                      Text(
                        trainerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // VISUAL ROLE INDICATOR (Explicitly flags user context as Trainer)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "OFFICIAL TRAINER",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              "CSS Evaluator",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // MAIN INTERFACE MODULES
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Learning Management"),
                      _buildModuleCard(
                        title: "Training Modules",
                        subtitle:
                            "View and manage CSS NC II learning materials.",
                        icon: Icons.menu_book_rounded,
                        accentColor: Colors.deepPurple,
                        onTap: () {},
                      ),
                      _buildModuleCard(
                        title: "Instructional Videos",
                        subtitle:
                            "Manage practical demonstrations and training videos.",
                        icon: Icons.video_library_rounded,
                        accentColor: Colors.purple,
                        onTap: () {},
                      ),

                      const SizedBox(height: 15),
                      _buildSectionHeader("Assessment Management"),
                      _buildModuleCard(
                        title: "Quizzes & Assessments",
                        subtitle: "Create and review knowledge assessments.",
                        icon: Icons.quiz_rounded,
                        accentColor: Colors.blue.shade800,
                        onTap: () {},
                      ),
                      _buildModuleCard(
                        title: "Performance Activities",
                        subtitle: "Create and review hands-on CSS activities.",
                        icon: Icons.assignment_rounded,
                        accentColor: Colors.indigo,
                        onTap: () {},
                      ),

                      const SizedBox(height: 15),
                      _buildSectionHeader("Competency Monitoring"),
                      _buildModuleCard(
                        title: "Trainee Progress Tracker",
                        subtitle:
                            "Monitor student learning progress and completion.",
                        icon: Icons.analytics_rounded,
                        accentColor: Colors.teal.shade700,
                        onTap: () {},
                      ),
                      _buildModuleCard(
                        title: "Competency Validation",
                        subtitle:
                            "Evaluate trainee readiness for CSS NC II assessment.",
                        icon: Icons.verified_user_rounded,
                        accentColor: Colors.green.shade700,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey.shade500,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.forum_rounded),
                label: 'Discussions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.black87,
        ),
      ),
    );
  }

  String _trainerName(Map<String, dynamic>? profile, User user) {
    final firstName = (profile?['firstName'] as String?)?.trim() ?? '';
    final middleName = (profile?['middleName'] as String?)?.trim() ?? '';
    final lastName = (profile?['lastName'] as String?)?.trim() ?? '';
    final extension = (profile?['extension'] as String?)?.trim() ?? '';

    final separatedName = [
      firstName,
      if (middleName.isNotEmpty)
        '${middleName.characters.first.toUpperCase()}.',
      lastName,
      if (extension.isNotEmpty) extension,
    ].where((part) => part.isNotEmpty).join(' ');

    if (separatedName.isNotEmpty) {
      return separatedName;
    }

    final savedName = profile?['name'] as String?;
    if (savedName != null && savedName.trim().isNotEmpty) {
      return savedName.trim();
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return 'CSS Trainer';
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: accentColor),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: accentColor.withOpacity(0.1),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
