import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:icteach/create_class.dart';
import 'package:icteach/utils/app_navigation.dart';
import 'package:icteach/screens/teacher/manage_modules_page.dart';
import 'package:icteach/screens/teacher/manage_quizzes_page.dart';
import 'package:icteach/screens/teacher/manage_assignments_page.dart';
import 'package:icteach/screens/teacher/progress_tracker_page.dart'; // ✅ ADD THIS IMPORT
import 'package:icteach/screens/student/forums_page.dart';
import 'package:icteach/screens/notification_page.dart';
import 'package:icteach/widgets/notification_badge.dart';
import 'class_roster.dart';
import 'login.dart';
import 'admin_login.dart';

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
        MaterialPageRoute(
          builder: (_) => kIsWeb ? const AdminLoginPage() : const LoginPage(),
        ),
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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF2F80ED,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    classData.className.isNotEmpty
                        ? classData.className[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Color(0xFF2F80ED),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  classData.className,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${classData.enrolledStudentIds?.length ?? 0} total enrolled',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

  Widget _buildTeacherProfile(User user, Map<String, dynamic>? profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Card with gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF2F80ED), const Color(0xFF1A5FA8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: 50,
                    color: const Color(0xFF2F80ED),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _teacherName(profile, user),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'No email',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    '👨‍🏫 Teacher',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats Card
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('classes')
                .where('teacherId', isEqualTo: user.uid)
                .get(),
            builder: (context, snapshot) {
              final classCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;

              int totalStudents = 0;
              int pendingReviews = 0;
              if (snapshot.hasData && snapshot.data != null) {
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>? ?? {};
                  final enrolledIds = List<String>.from(
                    data['enrolledStudentIds'] ?? [],
                  );
                  totalStudents += enrolledIds.length;
                  pendingReviews += data['pendingReviews'] as int? ?? 0;
                }
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ProfileStat(
                      label: 'Classes',
                      value: '$classCount',
                      icon: Icons.class_,
                      color: const Color(0xFF2F80ED),
                    ),
                    _ProfileStat(
                      label: 'Students',
                      value: '$totalStudents',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                    _ProfileStat(
                      label: 'Pending',
                      value: '$pendingReviews',
                      icon: Icons.pending,
                      color: Colors.orange,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.red.shade300),
              ),
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
            final totalEnrolled = classes.fold<int>(
              0,
              (total, item) => total + (item.enrolledStudentIds?.length ?? 0),
            );
            final pendingReviewCount = classes.fold<int>(
              0,
              (total, item) => total + (item.pendingReviews ?? 0),
            );

            return PopScope(
              canPop: _currentTabIndex == 0,
              onPopInvokedWithResult: (didPop, _) {
                if (didPop) return;
                setState(() => _currentTabIndex = 0);
              },
              child: Scaffold(
                backgroundColor: const Color(0xFFF4F7FA),
                body: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final desktop = constraints.maxWidth >= 1000;
                      final workspace = Column(
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
                                _buildHomeTab(
                                  context,
                                  classCount,
                                  totalEnrolled,
                                  pendingReviewCount,
                                ),
                                buildClassesTab(),
                                _buildDiscussionTab(),
                                _buildAnalyticsTab(),
                                _buildTeacherProfile(user, profile),
                              ],
                            ),
                          ),
                        ],
                      );
                      if (!desktop) return workspace;
                      return Row(
                        children: [
                          _TeacherDesktopNav(
                            currentIndex: _currentTabIndex,
                            teacherName: name,
                            onChanged: (index) =>
                                setState(() => _currentTabIndex = index),
                            onLogout: _logout,
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: workspace),
                        ],
                      );
                    },
                  ),
                ),
                bottomNavigationBar: MediaQuery.sizeOf(context).width >= 1000
                    ? null
                    : _TeacherBottomNavBar(
                        currentIndex: _currentTabIndex,
                        onTabChanged: (index) {
                          setState(() => _currentTabIndex = index);
                        },
                      ),
                floatingActionButton:
                    _currentTabIndex == 0 || _currentTabIndex == 1
                    ? FloatingActionButton(
                        heroTag: "createClass",
                        backgroundColor: const Color(0xFF2F80ED),
                        foregroundColor: Colors.white,
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
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeTab(
    BuildContext context,
    int classCount,
    int totalEnrolled,
    int pendingReviewCount,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        22,
        MediaQuery.sizeOf(context).width >= 1000 ? 16 : 24,
        22,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeacherSummary(
            classStream: _classesStream,
            totalEnrolled: totalEnrolled,
            pendingReviewCount: pendingReviewCount,
          ),
          SizedBox(height: MediaQuery.sizeOf(context).width >= 1000 ? 14 : 22),
          Text(
            'Teacher Tools',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _TeacherToolGrid(
            classCount: classCount,
            onManageClasses: () {
              setState(() {
                _currentTabIndex = 1;
              });
            },
            onSwitchTab: () {
              setState(() {
                _currentTabIndex = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                Icon(
                  Icons.forum_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No classes created',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a class to start discussions',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF2F80ED,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.forum_rounded,
                    color: const Color(0xFF2F80ED),
                  ),
                ),
                title: Text(
                  classData.className,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('View discussions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForumsPage(
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

  Widget _buildAnalyticsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                Icon(
                  Icons.analytics_rounded,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No classes found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a class to track progress',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
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
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2F80ED).withOpacity(0.1),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF2F80ED),
                  ),
                ),
                title: Text(
                  classData.className,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('View student progress & leaderboard'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgressTrackerPage(
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
      className:
          data['name']?.toString() ??
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2F80ED), const Color(0xFF1A5FA8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(23, 48, 23, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.co_present_rounded,
                color: Color(0xFF2F80ED),
                size: 32,
              ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'CSS NC II - Computer Systems Servicing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
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
                size: 26,
              ),
              tooltip: 'Notifications',
            ),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 26,
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
                    const Color(0xFF2F80ED),
                    Icons.class_,
                  ),
                  _SummaryCard(
                    'Enrolled',
                    totalEnrolled.toString(),
                    Colors.green,
                    Icons.people,
                  ),
                  _SummaryCard(
                    'Pending',
                    pendingReviewCount.toString(),
                    Colors.orange,
                    Icons.pending,
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
  const _SummaryCard(this.label, this.value, this.color, this.icon);

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ FIXED: _TeacherToolGrid with onSwitchTab callback
class _TeacherToolGrid extends StatelessWidget {
  const _TeacherToolGrid({
    required this.classCount,
    required this.onManageClasses,
    required this.onSwitchTab,
  });

  final int classCount;
  final VoidCallback onManageClasses;
  final VoidCallback onSwitchTab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 6
            : constraints.maxWidth >= 600
            ? 3
            : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: columns == 6 ? 10 : 12,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 6 ? 1.02 : 1.1,
          children: [
            _ToolCard(
              icon: Icons.class_,
              title: 'Manage Classes',
              subtitle: '$classCount classes',
              color: const Color(0xFF2F80ED),
              onTap: onManageClasses,
            ),
            _ToolCard(
              icon: Icons.people,
              title: 'Student Roster',
              subtitle: 'View all students',
              color: Colors.green,
              onTap: onSwitchTab,
            ),
            _ToolCard(
              icon: Icons.menu_book_rounded,
              title: 'Modules',
              subtitle: 'Create & manage',
              color: Colors.purple,
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
              subtitle: 'Create & manage',
              color: Colors.orange,
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
              color: Colors.red.shade400,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        _ModuleClassSelector(moduleType: 'assignments'),
                  ),
                );
              },
            ),
            _ToolCard(
              icon: Icons.forum_rounded,
              title: 'Forums',
              subtitle: 'Manage discussions',
              color: Colors.teal,
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
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 2),
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

class _TeacherDesktopNav extends StatelessWidget {
  const _TeacherDesktopNav({
    required this.currentIndex,
    required this.teacherName,
    required this.onChanged,
    required this.onLogout,
  });

  final int currentIndex;
  final String teacherName;
  final ValueChanged<int> onChanged;
  final VoidCallback onLogout;

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Overview'),
    (Icons.class_outlined, Icons.class_rounded, 'Classes'),
    (Icons.forum_outlined, Icons.forum_rounded, 'Discussions'),
    (Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics'),
    (Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/ict_logo.png', width: 42, height: 42),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ICTeach',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'TEACHER WORKSPACE',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF627487),
                      fontWeight: FontWeight.w700,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          for (var index = 0; index < _items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: currentIndex == index,
                selectedTileColor: const Color(0xFFEAF1FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: Icon(
                  currentIndex == index ? _items[index].$2 : _items[index].$1,
                ),
                title: Text(_items[index].$3),
                onTap: () => onChanged(index),
              ),
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline, size: 19),
            ),
            title: Text(
              teacherName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('Teacher'),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Sign out'),
            onTap: onLogout,
          ),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
        selectedItemColor: const Color(0xFF2F80ED),
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
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
      ),
    );
  }
}

// Profile Stat Widget
class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

// Module Class Selector with Forums Support
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

    final color = widget.moduleType == 'quizzes'
        ? Colors.orange
        : widget.moduleType == 'assignments'
        ? Colors.red.shade400
        : widget.moduleType == 'forums'
        ? Colors.teal
        : Colors.purple;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text('Manage $title'),
        backgroundColor: const Color(0xFF2F80ED),
        foregroundColor: Colors.white,
        elevation: 0,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      foregroundColor: Colors.white,
                    ),
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(icon, color: color),
                        ),
                        title: Text(
                          classData.className,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
