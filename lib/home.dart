import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'join_class.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No student signed in.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        final fullName = _getFullName(profile);
        final course =
            profile?['course'] as String? ??
            'CSS NC II - Computer System Servicing';

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // Header
                _buildHeader(fullName, user.photoURL),
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      // Tab 0: Home
                      _buildHomeContent(course),
                      // Tab 1: Course
                      const Center(child: Text('Course Content')),
                      // Tab 2: Forum
                      const Center(child: Text('Discussion Forums')),
                      // Tab 3: Progress
                      const Center(child: Text('Progress Tracking')),
                      // Tab 4: Profile
                      _buildProfileContent(profile, user),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildHeader(String name, String? photoUrl) {
    final timeOfDay = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (timeOfDay >= 12 && timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else if (timeOfDay >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      height: 130,
      width: double.infinity,
      color: const Color(0xFF428DEB),
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl),
            child: photoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF428DEB),
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(String course) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Back Section
          SizedBox(
            height: 70,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -30,
                  child: _buildHeartMascot(size: 85),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress Card
          _buildProgressCard(),

          const SizedBox(height: 24),

          // Quick Access Title
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 12),

          // Quick Access Grid
          _buildQuickAccessGrid(),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseAuth.instance.currentUser != null
          ? FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .collection('classes')
                .get()
          : null,
      builder: (context, snapshot) {
        final hasClass = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        String className = 'No Class Joined';
        if (hasClass) {
          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            className = data['className']?.toString() ?? 'Your Class';
          } else {
            className = 'Your Class';
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF428DEB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF428DEB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasClass ? 'Current Class' : 'Get Started',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            className,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!hasClass)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Join Now',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: hasClass ? 0.20 : 0.0,
                  color: const Color(0xFF428DEB),
                  backgroundColor: const Color(0xFFE5E7EB),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasClass
                        ? '1 of 5 modules completed'
                        : 'Join a class to start learning',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  if (hasClass)
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Keep going! →',
                        style: TextStyle(
                          color: Color(0xFF428DEB),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessGrid() {
    final items = [
      _QuickAccessItem(
        icon: Icons.menu_book_rounded,
        title: 'Learning Modules',
        subtitle: '5 modules',
        color: const Color(0xFF4F6DB8),
        bgColor: const Color(0xFFDCE6FF),
      ),
      _QuickAccessItem(
        icon: Icons.quiz_rounded,
        title: 'Quizzes',
        subtitle: '3 Available',
        color: const Color(0xFF9C4FA1),
        bgColor: const Color(0xFFE9C4EB),
      ),
      _QuickAccessItem(
        icon: Icons.assignment_rounded,
        title: 'Assignments',
        subtitle: '2 Pending',
        color: const Color(0xFFE76C31),
        bgColor: const Color(0xFFFFD7C2),
      ),
      _QuickAccessItem(
        icon: Icons.science_rounded,
        title: 'Simulations',
        subtitle: '5 Labs',
        color: const Color(0xFF168D92),
        bgColor: const Color(0xFFA6F4F5),
      ),
      _QuickAccessItem(
        icon: Icons.video_library_rounded,
        title: 'Instructional Videos',
        subtitle: '2 New',
        color: const Color(0xFFD97847),
        bgColor: const Color(0xFFFFCFB1),
      ),
      _QuickAccessItem(
        icon: Icons.forum_rounded,
        title: 'Discussion Forums',
        subtitle: 'Ask & Discuss',
        color: const Color(0xFF249A38),
        bgColor: const Color(0xFFC9F2CE),
      ),
    ];

    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _buildProfileContent(Map<String, dynamic>? profile, User user) {
    final firstName = profile?['firstName']?.toString() ?? '';
    final middleName = profile?['middleName']?.toString() ?? '';
    final lastName = profile?['lastName']?.toString() ?? '';
    final email = user.email ?? 'No email';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF428DEB).withOpacity(0.1),
                  backgroundImage: user.photoURL != null
                      ? NetworkImage(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(
                          Icons.person_rounded,
                          size: 50,
                          color: Color(0xFF428DEB),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _getFullName(profile),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF428DEB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Student',
                    style: TextStyle(
                      color: Color(0xFF428DEB),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Joined Class Section
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('classes')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final hasClass =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              final classDoc = hasClass ? snapshot.data!.docs.first : null;
              final classData = classDoc?.data() as Map<String, dynamic>? ?? {};
              final className = classData['className']?.toString() ?? '';
              final teacherName = classData['teacherName']?.toString() ?? '';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF428DEB).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.class_rounded,
                            color: Color(0xFF428DEB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Class',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasClass) ...[
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Teacher: $teacherName',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You haven\'t joined a class yet.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const JoinClassPage(),
                              ),
                            );
                            if (result == true && context.mounted) {
                              // Refresh
                            }
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Join a Class'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF428DEB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final items = [
      _NavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
      _NavItem(icon: Icons.menu_book_outlined, label: 'Course', index: 1),
      _NavItem(icon: Icons.forum_outlined, label: 'Forum', index: 2),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Progress', index: 3),
      _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', index: 4),
    ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          final isSelected = _currentTabIndex == item.index;
          return InkWell(
            onTap: () => setState(() => _currentTabIndex = item.index),
            child: SizedBox(
              width: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.icon,
                    color: isSelected
                        ? const Color(0xFF428DEB)
                        : Colors.grey.shade600,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF428DEB)
                          : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF428DEB),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getFullName(Map<String, dynamic>? profile) {
    final firstName = profile?['firstName']?.toString().trim() ?? '';
    final middleName = profile?['middleName']?.toString().trim() ?? '';
    final lastName = profile?['lastName']?.toString().trim() ?? '';
    final extension = profile?['extension']?.toString().trim() ?? '';

    if (firstName.isEmpty && lastName.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      return user?.displayName ?? 'Student';
    }

    String middleInitial = '';
    if (middleName.isNotEmpty) {
      middleInitial = '${middleName[0].toUpperCase()}.';
    }

    final parts = [firstName, middleInitial, lastName, extension];
    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  Widget _buildHeartMascot({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _HeartMascotPainter()),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;

  const _QuickAccessItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _HeartMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 85;
    canvas.scale(scale);

    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final heartFill = Paint()
      ..color = const Color(0xFFFF2F69)
      ..style = PaintingStyle.fill;
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final shoeFill = Paint()
      ..color = const Color(0xFF2677D8)
      ..style = PaintingStyle.fill;

    final heart = Path()
      ..moveTo(42, 26)
      ..cubicTo(37, 13, 16, 14, 15, 33)
      ..cubicTo(14, 49, 32, 59, 42, 70)
      ..cubicTo(52, 59, 70, 49, 69, 33)
      ..cubicTo(68, 14, 47, 13, 42, 26)
      ..close();
    canvas.drawPath(heart, heartFill);
    canvas.drawPath(heart, outline);

    canvas.drawCircle(const Offset(34, 36), 10, whiteFill);
    canvas.drawCircle(const Offset(50, 36), 10, whiteFill);
    canvas.drawCircle(const Offset(36, 37), 3.5, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(48, 37), 3.5, Paint()..color = Colors.black);

    final smile = Path()
      ..moveTo(34, 49)
      ..quadraticBezierTo(42, 55, 50, 49);
    canvas.drawPath(smile, outline);

    canvas.drawLine(const Offset(17, 43), const Offset(4, 33), outline);
    canvas.drawLine(const Offset(67, 43), const Offset(80, 32), outline);
    canvas.drawCircle(const Offset(4, 33), 3.5, whiteFill);
    canvas.drawCircle(const Offset(80, 32), 3.5, whiteFill);
    canvas.drawCircle(const Offset(4, 33), 3.5, outline);
    canvas.drawCircle(const Offset(80, 32), 3.5, outline);

    canvas.drawLine(const Offset(35, 67), const Offset(30, 80), outline);
    canvas.drawLine(const Offset(49, 67), const Offset(56, 80), outline);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 81), width: 17, height: 6),
      shoeFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(61, 81), width: 17, height: 6),
      shoeFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(25, 81), width: 17, height: 6),
      outline,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(61, 81), width: 17, height: 6),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
