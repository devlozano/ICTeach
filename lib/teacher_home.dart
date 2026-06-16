import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:icteach/create_class.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  // Tracks the active bottom navigation panel index
  int _currentTabIndex = 0;

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data?.data();
        final name = _teacherName(profile, user);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: teacherClassesStream(),
          builder: (context, classesSnapshot) {
            if (classesSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final classDocs = classesSnapshot.data?.docs ?? [];
            final classes = classDocs
                .map((doc) => _TeacherClassData.fromSnapshot(doc))
                .toList();
            final classCount = classes.length;
            final studentCount = classes.fold<int>(
              0,
              (total, item) => total + item.enrolledStudentIds.length,
            );
            final pendingReviewCount = classes.fold<int>(
              0,
              (total, item) => total + (item.pendingReviews ?? 0),
            );

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFF),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Create Class',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateClassPage(),
                        ),
                      );

                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _TeacherHeader(name: name),
                    Expanded(
                      child: IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          // TAB 0: Core Homepage Dashboard Grid View
                          SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TeacherSummary(
                                  classStream: teacherClassesStream(),
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
                          const Center(
                            child: Text(
                              'Tasks Authoring Hub (Use Case: Creates modules, quizzes & assignments)',
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Student Progress Analytics (Use Case: Monitors students progress)',
                            ),
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
            );
          },
        );
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> teacherClassesStream() {
    final user = FirebaseAuth.instance.currentUser;

    return FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: user!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Widget buildClassesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: teacherClassesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final classDocs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Class Roster',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateClassPage(),
                        ),
                      );

                      if (result == true && mounted) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Class'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: classDocs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'You have no classes yet. Create a class and share the section code with students so they can join.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      itemCount: classDocs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final doc = classDocs[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final name =
                            (data['name'] as String?)?.trim() ??
                            'Unnamed Class';
                        final description =
                            (data['description'] as String?)?.trim() ?? '';
                        final sectionCode =
                            (data['sectionCode'] as String?)?.trim() ?? 'UNKN';
                        final enrolledStudentIds = List<String>.from(
                          data['enrolledStudentIds'] as List<dynamic>? ?? [],
                        );

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          elevation: 1.5,
                          child: ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  description.isNotEmpty
                                      ? description
                                      : 'No description yet',
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Chip(label: Text('Code: $sectionCode')),
                                    Chip(
                                      label: Text(
                                        '${enrolledStudentIds.length} students',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _teacherName(Map<String, dynamic>? profile, User user) {
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

    return 'Teacher';
  }
}

class _TeacherClassData {
  _TeacherClassData({
    required this.id,
    required this.name,
    required this.description,
    required this.sectionCode,
    required this.enrolledStudentIds,
    required this.pendingReviews,
  });

  final String id;
  final String name;
  final String description;
  final String sectionCode;
  final List<String> enrolledStudentIds;
  final int? pendingReviews;

  factory _TeacherClassData.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return _TeacherClassData(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Unnamed Class',
      description: (data['description'] as String?)?.trim() ?? '',
      sectionCode: (data['sectionCode'] as String?)?.trim() ?? 'UNKN',
      enrolledStudentIds: List<String>.from(
        data['enrolledStudentIds'] as List<dynamic>? ?? [],
      ),
      pendingReviews: data['pendingReviews'] as int?,
    );
  }
}

class _TeacherHeader extends StatelessWidget {
  const _TeacherHeader({required this.name});
  final String name;

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
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 28,
            ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E7F4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: classStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return _SummaryItem(label: 'My Classes', value: '$count Classes');
            },
          ),
          const _SummaryDivider(),
          _SummaryItem(label: 'Students Active', value: '$studentCount'),
          const _SummaryDivider(),
          _SummaryItem(label: 'Pending Reviews', value: '$pendingReviewCount'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0868D8),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF656565),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: const Color(0xFFE2E2E2));
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
    final tools = [
      _TeacherToolItem(
        title: 'Manage Classes',
        subtitle: '$classCount sections assigned',
        icon: Icons.groups_rounded,
        color: const Color(0xFF2F80ED),
        background: const Color(0xFFDCEBFF),
        onTap: onManageClasses,
      ),
      _TeacherToolItem(
        title: 'Curriculum Modules',
        subtitle: 'Construct lesson tracks',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF4F6DB8),
        background: const Color(0xFFDCE6FF),
      ),
      _TeacherToolItem(
        title: 'Provide Feedback',
        subtitle: 'Review student submissions',
        icon: Icons.rate_review_rounded,
        color: const Color(0xFFE76C31),
        background: const Color(0xFFFFD7C2),
      ),
      _TeacherToolItem(
        title: 'Quizzes & Tests',
        subtitle: 'Formative design options',
        icon: Icons.quiz_outlined,
        color: const Color(0xFF9C4FA1),
        background: const Color(0xFFE9C4EB),
      ),
      _TeacherToolItem(
        title: 'Student Progress',
        subtitle: 'Monitor system pathways',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF249A38),
        background: const Color(0xFFC9F2CE),
      ),
      _TeacherToolItem(
        title: 'Discussion Forums',
        subtitle: 'Interact in threads',
        icon: Icons.forum_rounded,
        color: const Color(0xFF168D92),
        background: const Color(0xFFA6F4F5),
      ),
    ];

    return GridView.builder(
      itemCount: tools.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => tools[index],
    );
  }
}

class _TeacherToolItem extends StatelessWidget {
  const _TeacherToolItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(0.24),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFECECEC))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TeacherNavItem(
            label: 'Home',
            icon: Icons.home_outlined,
            selected: currentIndex == 0,
            onTap: () => onTabChanged(0),
          ),
          _TeacherNavItem(
            label: 'Classes',
            icon: Icons.groups_outlined,
            selected: currentIndex == 1,
            onTap: () => onTabChanged(1),
          ),
          _TeacherNavItem(
            label: 'Tasks',
            icon: Icons.assignment_outlined,
            selected: currentIndex == 2,
            onTap: () => onTabChanged(2),
          ),
          _TeacherNavItem(
            label: 'Progress',
            icon: Icons.bar_chart_rounded,
            selected: currentIndex == 3,
            onTap: () => onTabChanged(3),
          ),
          _TeacherNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            selected: currentIndex == 4,
            onTap: () => onTabChanged(4),
          ),
        ],
      ),
    );
  }
}

class _TeacherNavItem extends StatelessWidget {
  const _TeacherNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0868D8) : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0868D8) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
