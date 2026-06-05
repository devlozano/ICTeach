// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('No admin signed in.')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        final name = _adminName(profile, user);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1000;
            return Scaffold(
              backgroundColor: const Color(0xFFF5F6FA),
              body: SafeArea(
                child: Row(
                  children: [
                    if (isWide)
                      const _SideNav(), // permanent left nav for wide screens
                    Expanded(
                      child: Column(
                        children: [
                          _TopBar(name: name),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1200,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dashboard',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 28,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Welcome back to ICTeach',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    _SummaryRow(),
                                    const SizedBox(height: 18),
                                    _QuarterOverviewGrid(),
                                    const SizedBox(height: 18),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Expanded(
                                          flex: 3,
                                          child: _RecentActivityCard(),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          flex: 1,
                                          child: _QuickActionsCard(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              drawer: isWide
                  ? null
                  : const Drawer(child: _SideNav()), // mobile drawer
            );
          },
        );
      },
    );
  }

  String _adminName(Map<String, dynamic>? profile, User user) {
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

    if (separatedName.isNotEmpty) return separatedName;

    final savedName = profile?['name'] as String?;
    if (savedName != null && savedName.trim().isNotEmpty)
      return savedName.trim();

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return 'Administrator';
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context) {
    const navColor = Color(0xFF0B2B4A);
    const accent = Color(0xFF1EA4FF);
    return Container(
      width: 240,
      color: navColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: const [
              SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'IC',
                  style: TextStyle(
                    color: navColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'ICTeach',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _NavTile(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: true,
          ),
          _NavTile(icon: Icons.book_rounded, label: 'Courses'),
          _NavTile(icon: Icons.menu_book_rounded, label: 'Learning Modules'),
          _NavTile(
            icon: Icons.play_circle_fill_rounded,
            label: 'Instructional Videos',
          ),
          _NavTile(icon: Icons.quiz_rounded, label: 'Quizzes'),
          _NavTile(icon: Icons.assignment_rounded, label: 'Assignments'),
          _NavTile(icon: Icons.memory_rounded, label: 'Simulations'),
          _NavTile(icon: Icons.forum_rounded, label: 'Discussion Forum'),
          _NavTile(icon: Icons.show_chart_rounded, label: 'Student Progress'),
          _NavTile(icon: Icons.report_rounded, label: 'Reports'),
          const Spacer(),
          _NavTile(icon: Icons.settings_rounded, label: 'Settings'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? const Color(0xFF00A0FF) : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            alignment: Alignment.center,
            child: Icon(icon, color: activeColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: activeColor,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Text(
            'Admin Panel',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF666666),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Admin',
                      style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF1EA4FF),
                  child: Text(
                    'E',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow();

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SmallStat(title: 'Total Students', value: '8', subtitle: '7 active'),
      _SmallStat(title: 'Active Courses', value: '4', subtitle: '5 total'),
      _SmallStat(
        title: 'Completed Assignments',
        value: '2',
        subtitle: 'of 6 total',
      ),
      _SmallStat(title: 'Avg Quiz Score', value: '58%', subtitle: '4 quizzes'),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            SizedBox(width: 260, child: cards[index]),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8A)),
          ),
        ],
      ),
    );
  }
}

class _QuarterOverviewGrid extends StatelessWidget {
  _QuarterOverviewGrid({super.key});

  final List<_QuarterCardData> quarters = const [
    _QuarterCardData(
      title: 'Quarter 1',
      subtitle: 'Computer Systems',
      courses: 2,
      color: Color(0xFF2F80ED),
    ),
    _QuarterCardData(
      title: 'Quarter 2',
      subtitle: 'Networking',
      courses: 2,
      color: Color(0xFF28C76F),
    ),
    _QuarterCardData(
      title: 'Quarter 3',
      subtitle: 'Server Management',
      courses: 2,
      color: Color(0xFF9C4FA1),
    ),
    _QuarterCardData(
      title: 'Quarter 4',
      subtitle: 'Troubleshooting & Maintenance',
      courses: 2,
      color: Color(0xFFE94560),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quarter’s Overview - CSS NC II',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 12,
            spacing: 12,
            children: quarters.map((q) => _QuarterCard(data: q)).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuarterCardData {
  final String title;
  final String subtitle;
  final int courses;
  final Color color;
  const _QuarterCardData({
    required this.title,
    required this.subtitle,
    required this.courses,
    required this.color,
  });
}

class _QuarterCard extends StatelessWidget {
  const _QuarterCard({required this.data});
  final _QuarterCardData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${data.courses} courses',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.subtitle,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: 0.65,
              color: data.color,
              backgroundColor: const Color(0xFFF1F1F1),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFFBDBDBD),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Maria Santos - graded',
        date: 'April 26',
      ),
      _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Juan Dela Cruz - graded',
        date: 'April 26',
      ),
      _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Carlos Garcia - graded',
        date: 'April 26',
      ),
      _ActivityItem(
        title: 'Computer Hardware Identification Quiz',
        subtitle: '33 submissions',
        date: 'April 26',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityRow(item: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String date;
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final _ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.assignment_rounded, color: Color(0xFFE76C31)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                style: const TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
              ),
            ],
          ),
        ),
        Text(
          item.date,
          style: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(label: 'Add CSS NC II Module', icon: Icons.add),
      _ActionItem(label: 'Add Lab Simulation', icon: Icons.add_circle_outline),
      _ActionItem(label: 'Create Assessment', icon: Icons.add_task),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          ...actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActionRow(action: a),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  const _ActionItem({required this.label, required this.icon});
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});
  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(action.icon, color: const Color(0xFF168D92)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
        ],
      ),
    );
  }
}
