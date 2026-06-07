import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  // Track the currently active panel screen view state string value
  String _currentSelectedLabel = 'Dashboard';

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
              // Setup a GlobalKey or use context directly if needing to control the drawer.
              // Scaffold automatically hooks up the menu button when a drawer is present.
              drawer: isWide
                  ? null
                  : Drawer(
                      child: _SideNav(
                        currentSelection: _currentSelectedLabel,
                        onSelected: (label) {
                          setState(() => _currentSelectedLabel = label);
                          Navigator.of(
                            context,
                          ).pop(); // Close drawer on selection
                        },
                      ),
                    ),
              body: SafeArea(
                child: Row(
                  children: [
                    if (isWide)
                      _SideNav(
                        currentSelection: _currentSelectedLabel,
                        onSelected: (label) {
                          setState(() => _currentSelectedLabel = label);
                        },
                      ), // permanent left nav for wide screens
                    Expanded(
                      child: Column(
                        children: [
                          // Pass isWide flag so the TopBar can show/hide the drawer menu button
                          _TopBar(name: name, showMenuButton: !isWide),
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
                                      _currentSelectedLabel,
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
                                      _currentSelectedLabel == 'Dashboard'
                                          ? 'Welcome back to ICTeach'
                                          : 'Manage your ICTeach $_currentSelectedLabel infrastructure configurations',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(height: 18),

                                    // ALIGNED: Render panel views dynamically using helper
                                    _buildActivePanelContent(),

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
            );
          },
        );
      },
    );
  }

  /// Helper to route layouts depending on navigation state selection
  Widget _buildActivePanelContent() {
    if (_currentSelectedLabel == 'Dashboard') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(),
          SizedBox(height: 18),
          _QuarterOverviewGrid(),
          SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _RecentActivityCard()),
              SizedBox(width: 16),
              Expanded(flex: 1, child: _QuickActionsCard()),
            ],
          ),
        ],
      );
    }

    // Secondary Management View Dynamic Call Fallbacks
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Center(
        child: Text(
          '$_currentSelectedLabel Sub-Panel Management View Coming Soon.',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black45,
          ),
        ),
      ),
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
    if (savedName != null && savedName.trim().isNotEmpty) {
      return savedName.trim();
    }

    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return 'Administrator';
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.currentSelection, required this.onSelected});

  final String currentSelection;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const navColor = Color(0xFF0B2B4A);
    return Container(
      width: 240,
      color: navColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          const Row(
            children: [
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavTile(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  selected: currentSelection == 'Dashboard',
                  onTap: () => onSelected('Dashboard'),
                ),
                _NavTile(
                  icon: Icons.book_rounded,
                  label: 'Courses',
                  selected: currentSelection == 'Courses',
                  onTap: () => onSelected('Courses'),
                ),
                _NavTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Learning Modules',
                  selected: currentSelection == 'Learning Modules',
                  onTap: () => onSelected('Learning Modules'),
                ),
                _NavTile(
                  icon: Icons.play_circle_fill_rounded,
                  label: 'Instructional Videos',
                  selected: currentSelection == 'Instructional Videos',
                  onTap: () => onSelected('Instructional Videos'),
                ),
                _NavTile(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  selected: currentSelection == 'Quizzes',
                  onTap: () => onSelected('Quizzes'),
                ),
                _NavTile(
                  icon: Icons.assignment_rounded,
                  label: 'Assignments',
                  selected: currentSelection == 'Assignments',
                  onTap: () => onSelected('Assignments'),
                ),
                _NavTile(
                  icon: Icons.memory_rounded,
                  label: 'Simulations',
                  selected: currentSelection == 'Simulations',
                  onTap: () => onSelected('Simulations'),
                ),
                _NavTile(
                  icon: Icons.forum_rounded,
                  label: 'Discussion Forum',
                  selected: currentSelection == 'Discussion Forum',
                  onTap: () => onSelected('Discussion Forum'),
                ),
                _NavTile(
                  icon: Icons.show_chart_rounded,
                  label: 'Student Progress',
                  selected: currentSelection == 'Student Progress',
                  onTap: () => onSelected('Student Progress'),
                ),
                _NavTile(
                  icon: Icons.report_rounded,
                  label: 'Reports',
                  selected: currentSelection == 'Reports',
                  onTap: () => onSelected('Reports'),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          _NavTile(
            icon: Icons.settings_rounded,
            label: 'Settings',
            selected: currentSelection == 'Settings',
            onTap: () => onSelected('Settings'),
          ),
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
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = selected ? const Color(0xFF1EA4FF) : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.04),
          splashColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  alignment: Alignment.center,
                  child: Icon(icon, color: activeColor, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.name, required this.showMenuButton});
  final String name;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // ALIGNED: Added mobile trigger support icon button
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0B2B4A)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
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
      const _SmallStat(
        title: 'Total Students',
        value: '8',
        subtitle: '7 active',
      ),
      const _SmallStat(
        title: 'Active Courses',
        value: '4',
        subtitle: '5 total',
      ),
      const _SmallStat(
        title: 'Completed Assignments',
        value: '2',
        subtitle: 'of 6 total',
      ),
      const _SmallStat(
        title: 'Avg Quiz Score',
        value: '58%',
        subtitle: '4 quizzes',
      ),
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
            color: Colors.black.withValues(alpha: 0.04),
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
  const _QuarterOverviewGrid();

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
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
      const _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Maria Santos - graded',
        date: 'April 26',
      ),
      const _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Juan Dela Cruz - graded',
        date: 'April 26',
      ),
      const _ActivityItem(
        title: 'PC Disassembly and Reassembly Lab Report',
        subtitle: 'Carlos Garcia - graded',
        date: 'April 26',
      ),
      const _ActivityItem(
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
      const _ActionItem(label: 'Add CSS NC II Module', icon: Icons.add),
      const _ActionItem(
        label: 'Add Lab Simulation',
        icon: Icons.add_circle_outline,
      ),
      const _ActionItem(label: 'Create Assessment', icon: Icons.add_task),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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
        ),
      ),
    );
  }
}
