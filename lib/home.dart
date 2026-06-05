import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
        final name = _studentName(profile, user);
        final course =
            profile?['course'] as String? ??
            'CSS NC II - Computer System Servicing';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                _HomeHeader(name: name, photoUrl: user.photoURL),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeSection(course: course),
                        const SizedBox(height: 18),
                        const _ProgressCard(),
                        const SizedBox(height: 20),
                        Text(
                          'Quick Access',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const _QuickAccessGrid(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const _BottomNavBar(),
        );
      },
    );
  }

  String _studentName(Map<String, dynamic>? profile, User user) {
    final firstName = (profile?['firstName'] as String?)?.trim() ?? '';
    final middleName = (profile?['middleName'] as String?)?.trim() ?? '';
    final lastName = (profile?['lastName'] as String?)?.trim() ?? '';
    final extension = (profile?['extension'] as String?)?.trim() ?? '';
    final separatedName = [
      firstName,
      if (middleName.isNotEmpty) _middleInitial(middleName),
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

    return 'Student';
  }

  String _middleInitial(String middleName) {
    final firstLetter = middleName.trim().characters.first.toUpperCase();
    return '$firstLetter.';
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.name, required this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 149,
      width: double.infinity,
      color: const Color(0xFF428DEB),
      padding: const EdgeInsets.fromLTRB(23, 43, 23, 22),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            backgroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
            child: photoUrl == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Color(0xFF428DEB),
                    size: 34,
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
                  'Good Morning,',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
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

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({required this.course});

  final String course;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  course,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4F4F4F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(right: -3, top: -28, child: _HeartMascot(size: 94)),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 15, 24, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 4),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress....',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 13,
              value: 0.45,
              color: const Color(0xFF0868D8),
              backgroundColor: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 7),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 of 5 modules completed',
                style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 11),
              ),
              Text(
                'Keep going!',
                style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    const cards = [
      _QuickAccessItem(
        title: 'Learning\nModules',
        subtitle: '5 modules',
        icon: Icons.menu_book_rounded,
        iconColor: Color(0xFF4F6DB8),
        iconBackground: Color(0xFFDCE6FF),
      ),
      _QuickAccessItem(
        title: 'Quizzes',
        subtitle: '3 Available',
        icon: Icons.quiz_outlined,
        iconColor: Color(0xFF9C4FA1),
        iconBackground: Color(0xFFE9C4EB),
      ),
      _QuickAccessItem(
        title: 'Assignments',
        subtitle: '2 Pending',
        icon: Icons.assignment_outlined,
        iconColor: Color(0xFFE76C31),
        iconBackground: Color(0xFFFFA06C),
      ),
      _QuickAccessItem(
        title: 'Simulations',
        subtitle: '5 Labs',
        icon: Icons.gamepad_outlined,
        iconColor: Color(0xFF249A38),
        iconBackground: Color(0xFF6FD879),
      ),
      _QuickAccessItem(
        title: 'Instructional\nVideos',
        subtitle: '2 New',
        icon: Icons.play_circle_outline_rounded,
        iconColor: Color(0xFFD97847),
        iconBackground: Color(0xFFFFCFB1),
      ),
      _QuickAccessItem(
        title: 'Discussion\nForums',
        subtitle: 'Ask & Discuss',
        icon: Icons.forum_rounded,
        iconColor: Color(0xFF168D92),
        iconBackground: Color(0xFFA6F4F5),
      ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEDEDED), width: 3),
      ),
      child: GridView.builder(
        itemCount: cards.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.28,
          crossAxisSpacing: 18,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  const _QuickAccessItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 41,
                      height: 41,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: const Color(0xFFD9D9D9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(label: 'Home', icon: Icons.home_outlined, isSelected: true),
          _NavItem(label: 'Course', icon: Icons.menu_book_outlined),
          _NavItem(label: 'Forum', icon: Icons.forum_outlined),
          _NavItem(label: 'Progress', icon: Icons.bar_chart_rounded),
          _NavItem(label: 'Profile', icon: Icons.person_outline_rounded),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  final String label;
  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFF0868D8) : Colors.black54;

    return SizedBox(
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
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0868D8) : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartMascot extends StatelessWidget {
  const _HeartMascot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _HeartMascotPainter());
  }
}

class _HeartMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 94;
    canvas.scale(scale);

    final outline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
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
      ..moveTo(47, 29)
      ..cubicTo(41, 14, 18, 15, 17, 36)
      ..cubicTo(16, 54, 35, 65, 47, 77)
      ..cubicTo(59, 65, 78, 54, 77, 36)
      ..cubicTo(76, 15, 53, 14, 47, 29)
      ..close();
    canvas.drawPath(heart, heartFill);
    canvas.drawPath(heart, outline);

    canvas.drawCircle(const Offset(38, 39), 11, whiteFill);
    canvas.drawCircle(const Offset(56, 39), 11, whiteFill);
    canvas.drawCircle(const Offset(40, 40), 4, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(54, 40), 4, Paint()..color = Colors.black);

    final smile = Path()
      ..moveTo(38, 54)
      ..quadraticBezierTo(47, 61, 57, 54);
    canvas.drawPath(smile, outline);

    canvas.drawLine(const Offset(19, 48), const Offset(4, 36), outline);
    canvas.drawLine(const Offset(75, 48), const Offset(88, 35), outline);
    canvas.drawCircle(const Offset(4, 36), 4, whiteFill);
    canvas.drawCircle(const Offset(88, 35), 4, whiteFill);
    canvas.drawCircle(const Offset(4, 36), 4, outline);
    canvas.drawCircle(const Offset(88, 35), 4, outline);

    canvas.drawLine(const Offset(39, 74), const Offset(33, 88), outline);
    canvas.drawLine(const Offset(55, 74), const Offset(63, 88), outline);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 89), width: 19, height: 7),
      shoeFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(68, 89), width: 19, height: 7),
      shoeFill,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(28, 89), width: 19, height: 7),
      outline,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(68, 89), width: 19, height: 7),
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
