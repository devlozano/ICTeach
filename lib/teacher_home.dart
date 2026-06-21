import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icteach/create_class.dart';
import 'package:icteach/utils/app_navigation.dart';
import 'package:icteach/screens/teacher/manage_modules_page.dart';
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

  // ✅ FIXED: Return empty stream instead of using QuerySnapshot._()
  Stream<QuerySnapshot<Map<String, dynamic>>> teacherClassesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Return an empty stream instead of trying to create a QuerySnapshot
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

    final firstName = profile['firstName']?.toString().trim() ?? '';
    final lastName = profile['lastName']?.toString().trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      return user.displayName ?? 'Teacher';
    }

    final parts = [firstName, lastName];
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
                  '${classData.enrolledStudentIds?.length ?? 0} students',
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
            final studentCount = classes.fold<int>(
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
                    _TeacherHeader(name: name, onLogout: _logout),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TeacherSummary(
                                  classStream: _classesStream,
                                  studentCount: studentCount,
                                  pendingReviewCount: pendingReviewCount,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Teacher Tools',
                                  style: Theme.of(context).textTheme.titleMedium
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
                          buildClassesTab(),
                          const Center(child: Text('Discussion Forums')),
                          const Center(
                            child: Text('Student Progress Analytics'),
                          ),
                          const Center(
                            child: Text('Teacher Profile Configurations'),
                          ),
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
      className: data['className'] ?? 'Untitled Class',
      teacherId: data['teacherId'] ?? '',
      enrolledStudentIds: List<String>.from(data['enrolledStudentIds'] ?? []),
      pendingReviews: data['pendingReviews'] as int?,
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({required this.name, required this.onLogout});

  final String name;
  final VoidCallback onLogout;

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
                    color: Colors.white.withOpacity(0.84),
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

class _TeacherSummary extends StatelessWidget {
  const _TeacherSummary({
    required this.classStream,
    required this.studentCount,
    required this.pendingReviewCount,
  });

  final Stream<QuerySnapshot<Map<String, dynamic>>> classStream;
  final int studentCount;
  final int pendingReviewCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8),
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
              _SummaryCard('Classes', '0', Colors.blue.shade300),
              _SummaryCard(
                'Students',
                studentCount.toString(),
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
          color: color.withOpacity(0.1),
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
          onTap: () {},
        ),
        _TrainerToolItem(
          title: 'Learning Modules',
          subtitle: 'Manage modules',
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF4F6DB8),
          bgColor: const Color(0xFFDCE6FF),
          onTap: () async {
            // Navigate to select a class to manage modules
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _ModuleClassSelector()),
            );
          },
        ),
        _ToolCard(
          icon: Icons.assessment,
          title: 'Assessments',
          subtitle: 'Create & manage',
          onTap: () {},
        ),
        _ToolCard(
          icon: Icons.bar_chart,
          title: 'Analytics',
          subtitle: 'Performance data',
          onTap: () {},
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
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
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

class _TrainerToolItem extends StatelessWidget {
  const _TrainerToolItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bgColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
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

class _ModuleClassSelector extends StatefulWidget {
  const _ModuleClassSelector();

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
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Select Class to Manage Modules'),
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
            return const Center(
              child: Text('No classes found. Create a class first.'),
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
                    '${classData.enrolledStudentIds?.length ?? 0} students',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageModulesPage(
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
      ),
    );
  }
}
