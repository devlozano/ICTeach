import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icteach/create_class.dart';
import 'package:icteach/utils/app_navigation.dart';
import 'package:icteach/screens/teacher/manage_modules_page.dart';
import 'package:icteach/screens/teacher/manage_quizzes_page.dart';
import 'package:icteach/screens/teacher/manage_assignments_page.dart';
import 'package:icteach/screens/student/forums_page.dart';
import 'package:icteach/screens/notification_page.dart';
import 'package:icteach/widgets/notification_badge.dart';
import 'package:icteach/screens/debug_page.dart';
import 'class_roster.dart';
import 'login.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentTabIndex = 0;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _classesStream;

  @override
  void initState() {
    super.initState();
    _classesStream = teacherClassesStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> teacherClassesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  String _teacherName(Map<String, dynamic>? profile, User user) {
    if (profile == null) {
      return user.displayName ?? 'Teacher';
    }

    // ✅ First try to get the full name from the 'name' field
    if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
      return profile['name'].toString();
    }

    final firstName = profile['firstName']?.toString().trim() ?? '';
    final middleName = profile['middleName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';
    final extension = profile['extension']?.toString().trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return user.displayName ?? 'Teacher';
    }

    final parts = [firstName, middleName, lastName, extension];
    final fullName = parts.where((p) => p.isNotEmpty).join(' ');

    return fullName.isNotEmpty ? fullName : 'Teacher';
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget buildClassesTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _classesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final classDocs = snapshot.data?.docs ?? [];
        if (classDocs.isEmpty) {
          return const Center(
            child: Text('No classes created yet. Tap + to create one.'),
          );
        }

        final classes = classDocs
            .map((doc) => _TeacherClassData.fromSnapshot(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(classData.className),
                subtitle: Text(
                  '${classData.enrolledStudentIds?.length ?? 0} total enrolled',
                ),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassRosterPage(
                        classId: classData.classId,
                        className: classData.className,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ✅ Profile Tab
  Widget _buildTeacherProfile(User user, Map<String, dynamic>? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _teacherName(profile, user),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Teacher',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Settings Section
          Card(
            child: Column(
              children: [
                // ✅ Debug Tools
                ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.purple),
                  title: const Text('Debug Tools'),
                  subtitle: const Text('Test notifications and debug data'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DebugPage(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No teacher signed in.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        final name = _teacherName(profile, user);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _classesStream,
          builder: (context, classesSnapshot) {
            final classDocs = classesSnapshot.data?.docs ?? [];
            final classes = classDocs
                .map((doc) => _TeacherClassData.fromSnapshot(doc))
                .toList();
            final classCount = classes.length;

            // ✅ Count total enrolled users (students + trainers)
            final totalEnrolled = classes.fold<int>(
              0,
              (total, item) => total + (item.enrolledStudentIds?.length ?? 0),
            );

            final pendingReviewCount = classes.fold<int>(
              0,
              (total, item) => total + (item.pendingReviews ?? 0),
            );

            return Scaffold(
              backgroundColor: const Color(0xffF8FAFC),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _TeacherHeader(
                      name: name,
                      onLogout: _logout,
                      classStream: _classesStream,
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          // Tab 0: Home
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TeacherSummary(
                                  classStream: _classesStream,
                                  totalEnrolled: totalEnrolled,
                                  pendingReviewCount: pendingReviewCount,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Teacher Tools',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 10),
                                _TeacherToolGrid(
                                  classCount: classCount,
                                  onManageClasses: () {
                                    setState(() {
                                      _currentTabIndex = 1;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Tab 1: Classes
                          buildClassesTab(),
                          // Tab 2: Discussion
                          const Center(child: Text('Discussion Forums')),
                          // Tab 3: Analytics
                          const Center(
                            child: Text('Student Progress Analytics'),
                          ),
                          // Tab 4: Profile
                          _buildTeacherProfile(user, profile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: _TeacherBottomNavBar(
                currentIndex: _currentTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: "createClass",
                child: const Icon(Icons.add),
                onPressed: () async {
                  final result = await AppNavigation.push(
                    context,
                    const CreateClassPage(),
                  );

                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ✅ FIXED: _TeacherClassData now uses 'name' field
class _TeacherClassData {
  final String classId;
  final String className;
  final String teacherId;
  final List<String>? enrolledStudentIds;
  final int? pendingReviews;

  _TeacherClassData({
    required this.classId,
    required this.className,
    required this.teacherId,
    this.enrolledStudentIds,
    this.pendingReviews,
  });

  factory _TeacherClassData.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _TeacherClassData(
      classId: doc.id,
      // ✅ FIXED: Use 'name' field, fallback to 'className' for backward compatibility
      className: data['name']?.toString() ??
          data['className']?.toString() ??
          'Untitled Class',
      teacherId: data['teacherId'] ?? '',
      enrolledStudentIds: List<String>.from(data['enrolledStudentIds'] ?? []),
      pendingReviews: data['pendingReviews'] as int?,
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({
    required this.name,
    required this.onLogout,
    required this.classStream,
  });

  final String name;
  final VoidCallback onLogout;
  final Stream<QuerySnapshot<Map<String, dynamic>>> classStream;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      width: double.infinity,
      color: const Color(0xFF2F80ED),
      padding: const EdgeInsets.fromLTRB(23, 48, 23, 24),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 33,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.co_present_rounded,
              color: Color(0xFF2F80ED),
              size: 36,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, Teacher',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'CSS NC II - Computer Systems Servicing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ✅ Notification Badge
          NotificationBadge(
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Notifications',
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 28,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

// ✅ UPDATED: _TeacherSummary with totalEnrolled
class _TeacherSummary extends StatelessWidget {
  const _TeacherSummary({
    required this.classStream,
    required this.totalEnrolled,
    required this.pendingReviewCount,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> classStream;
  final int totalEnrolled;
  final int pendingReviewCount;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: classStream,
      builder: (context, snapshot) {
        final classCount = snapshot.data?.docs.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryCard(
                    'Classes',
                    classCount.toString(),
                    Colors.blue.shade300,
                  ),
                  _SummaryCard(
                    'Enrolled',
                    totalEnrolled.toString(),
                    Colors.green.shade300,
                  ),
                  _SummaryCard(
                    'Pending',
                    pendingReviewCount.toString(),
                    Colors.orange.shade300,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ UPDATED: Teacher Tool Grid with Forums
class _TeacherToolGrid extends StatelessWidget {
  const _TeacherToolGrid({
    required this.classCount,
    required this.onManageClasses,
  });

  final int classCount;
  final VoidCallback onManageClasses;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _ToolCard(
          icon: Icons.class_,
          title: 'Manage Classes',
          subtitle: '$classCount classes',
          onTap: onManageClasses,
        ),
        _ToolCard(
          icon: Icons.people,
          title: 'Student Roster',
          subtitle: 'View all students',
          onTap: () {
            // Navigate to Classes tab
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Go to Classes tab to view roster'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        _ToolCard(
          icon: Icons.menu_book_rounded,
          title: 'Learning Modules',
          subtitle: 'Create & manage modules',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ModuleClassSelector(moduleType: 'modules'),
              ),
            );
          },
        ),
        _ToolCard(
          icon: Icons.quiz_rounded,
          title: 'Quizzes',
          subtitle: 'Create & manage quizzes',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ModuleClassSelector(moduleType: 'quizzes'),
              ),
            );
          },
        ),
        _ToolCard(
          icon: Icons.assignment_rounded,
          title: 'Assignments',
          subtitle: 'Create & manage',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ModuleClassSelector(moduleType: 'assignments'),
              ),
            );
          },
        ),
        _ToolCard(
          icon: Icons.forum_rounded,
          title: 'Forums',
          subtitle: 'Manage discussions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _ModuleClassSelector(moduleType: 'forums'),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2F80ED)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherBottomNavBar extends StatelessWidget {
  const _TeacherBottomNavBar({
    required this.currentIndex,
    required this.onTabChanged,
  });

  final int currentIndex;
  final Function(int) onTabChanged;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabChanged,
      selectedItemColor: const Color(0xFF2F80ED),
      unselectedItemColor: Colors.grey.shade400,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.class_rounded),
          label: 'Classes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.forum_rounded),
          label: 'Discussion',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

// ✅ UPDATED: Module Class Selector with Forums Support
class _ModuleClassSelector extends StatefulWidget {
  final String moduleType;

  const _ModuleClassSelector({required this.moduleType});

  @override
  State<_ModuleClassSelector> createState() => _ModuleClassSelectorState();
}

class _ModuleClassSelectorState extends State<_ModuleClassSelector> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _classesStream;

  @override
  void initState() {
    super.initState();
    _classesStream = teacherClassesStream();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> teacherClassesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.moduleType == 'quizzes'
        ? 'Quizzes'
        : widget.moduleType == 'assignments'
            ? 'Assignments'
            : widget.moduleType == 'forums'
                ? 'Forums'
                : 'Modules';

    final subtitle = widget.moduleType == 'quizzes'
        ? 'Select a class to manage quizzes'
        : widget.moduleType == 'assignments'
            ? 'Select a class to manage assignments'
            : widget.moduleType == 'forums'
                ? 'Select a class to manage discussions'
                : 'Select a class to manage modules';

    final icon = widget.moduleType == 'quizzes'
        ? Icons.quiz
        : widget.moduleType == 'assignments'
            ? Icons.assignment
            : widget.moduleType == 'forums'
                ? Icons.forum
                : Icons.menu_book;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text('Manage $title'),
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _classesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final classDocs = snapshot.data?.docs ?? [];
          if (classDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.class_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No classes found',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a class first to manage $title',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final classes = classDocs
              .map((doc) => _TeacherClassData.fromSnapshot(doc))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: classes.length,
                  itemBuilder: (context, index) {
                    final classData = classes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              const Color(0xFF2F80ED).withValues(alpha: 0.1),
                          child: Icon(
                            icon,
                            color: const Color(0xFF2F80ED),
                          ),
                        ),
                        title: Text(
                          classData.className,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${classData.enrolledStudentIds?.length ?? 0} total enrolled',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (widget.moduleType == 'quizzes') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ManageQuizzesPage(
                                  classId: classData.classId,
                                  className: classData.className,
                                ),
                              ),
                            );
                          } else if (widget.moduleType == 'assignments') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ManageAssignmentsPage(
                                  classId: classData.classId,
                                  className: classData.className,
                                ),
                              ),
                            );
                          } else if (widget.moduleType == 'forums') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ForumsPage(
                                  classId: classData.classId,
                                  className: classData.className,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ManageModulesPage(
                                  classId: classData.classId,
                                  className: classData.className,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
