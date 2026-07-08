import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin/create_staff_page.dart';
import 'admin/manage_trainers_page.dart'; // ✅ ADD THIS IMPORT
import 'package:icteach/screens/notification_page.dart'; // ✅ ADD THIS
import 'package:icteach/widgets/notification_badge.dart'; // ✅ ADD THIS

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
              backgroundColor: const Color(0xffF8FAFC),
              drawer: isWide
                  ? null
                  : Drawer(
                      child: _SideNav(
                        currentSelection: _currentSelectedLabel,
                        onSelected: (label) {
                          setState(() => _currentSelectedLabel = label);
                          Navigator.of(
                            context,
                          ).pop();
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
                      ),
                    Expanded(
                      child: Column(
                        children: [
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
  /// Helper to route layouts depending on navigation state selection
  Widget _buildActivePanelContent() {
    if (_currentSelectedLabel == 'Dashboard') {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(),
          SizedBox(height: 18),
          _RecentClassesGrid(),
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

    // ✅ FIXED: Manage Users - Show Trainers and Teachers
    if (_currentSelectedLabel == 'Manage Users') {
      return _ManageUsersContent();
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

  // ✅ NEW: Manage Users Content
  // ✅ FIXED: Manage Users Content
  Widget _ManageUsersContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teacher Management Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Teachers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateStaffPage(selectedRole: 'teacher'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Teacher'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2B4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ✅ FIXED: Teacher List with proper scope
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'teacher')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final teachers = snapshot.data?.docs ?? [];

                  if (teachers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No teachers found'),
                      ),
                    );
                  }

                  // ✅ FIXED: Now teachers is in scope for the if condition
                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teachers.length > 3 ? 3 : teachers.length,
                        itemBuilder: (context, index) {
                          final doc = teachers[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};
                          final name = data['name']?.toString() ?? 'Unknown';
                          final email = data['email']?.toString() ?? '';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF2F80ED).withOpacity(0.1),
                              child: const Icon(Icons.person_outline,
                                  color: Color(0xFF2F80ED)),
                            ),
                            title: Text(name),
                            subtitle: Text(email),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // View teacher details
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Teacher details coming soon!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // ✅ FIXED: Now teachers is in scope here
                      if (teachers.length > 3)
                        TextButton(
                          onPressed: () {
                            // Navigate to full teacher list
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Full teacher list coming soon!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text('View all teachers →'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Trainer Management Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Trainers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateStaffPage(selectedRole: 'trainer'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Trainer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageTrainersPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.verified_user, color: Colors.purple),
                  label: const Text('View All Trainers'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: const BorderSide(color: Colors.purple),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage trainer accounts, assign to classes, and track their performance.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  icon: Icons.people_alt_rounded,
                  label: 'Manage Users',
                  selected: currentSelection == 'Manage Users',
                  onTap: () => onSelected('Manage Users'),
                ),
                _NavTile(
                  icon: Icons.class_rounded,
                  label: 'Manage Classes',
                  selected: currentSelection == 'Manage Classes',
                  onTap: () => onSelected('Manage Classes'),
                ),
                _NavTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Performance',
                  selected: currentSelection == 'Performance',
                  onTap: () => onSelected('Performance'),
                ),
                _NavTile(
                  icon: Icons.assessment_rounded,
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
          // ✅ ADD NOTIFICATION BADGE HERE
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

class _SummaryRow extends StatefulWidget {
  const _SummaryRow();

  @override
  State<_SummaryRow> createState() => _SummaryRowState();
}

class _SummaryRowState extends State<_SummaryRow> {
  int totalUsers = 0;
  int teachers = 0;
  int trainers = 0;
  int students = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = FirebaseFirestore.instance;
      
      final total = await db.collection('users').count().get();
      final teachersCount = await db.collection('users').where('role', isEqualTo: 'teacher').count().get();
      final trainersCount = await db.collection('users').where('role', isEqualTo: 'trainer').count().get();
      final studentsCount = await db.collection('users').where('role', isEqualTo: 'student').count().get();
      
      if (mounted) {
        setState(() {
          totalUsers = total.count ?? 0;
          teachers = teachersCount.count ?? 0;
          trainers = trainersCount.count ?? 0;
          students = studentsCount.count ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 112,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    final cards = [
      _SmallStat(
        title: 'Total Users',
        value: totalUsers.toString(),
        subtitle: 'All registered accounts',
      ),
      _SmallStat(
        title: 'Teachers',
        value: teachers.toString(),
        subtitle: 'Active teachers',
      ),
      _SmallStat(
        title: 'Trainers',
        value: trainers.toString(),
        subtitle: 'Industry trainers',
      ),
      _SmallStat(
        title: 'Students',
        value: students.toString(),
        subtitle: 'Currently enrolled',
      ),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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

class _RecentClassesGrid extends StatelessWidget {
  const _RecentClassesGrid();

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
            'Recent Classes',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .orderBy('createdAt', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No classes found'),
                );
              }
              
              final docs = snapshot.data!.docs;
              final colors = [
                const Color(0xFF2F80ED),
                const Color(0xFF28C76F),
                const Color(0xFF9C4FA1),
                const Color(0xFFE94560),
              ];
              
              return Wrap(
                runSpacing: 12,
                spacing: 12,
                children: List.generate(docs.length, (index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? 'Untitled Class';
                  final section = data['sectionCode'] as String? ?? 'No section';
                  final students = (data['enrolledStudentIds'] as List?)?.length ?? 0;
                  final color = colors[index % colors.length];
                  
                  return _ClassCard(
                    title: name,
                    subtitle: section,
                    studentsCount: students,
                    color: color,
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.title,
    required this.subtitle,
    required this.studentsCount,
    required this.color,
  });

  final String title;
  final String subtitle;
  final int studentsCount;
  final Color color;

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
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$studentsCount students',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: studentsCount > 0 ? 1.0 : 0.0, // Just a placeholder for now
              color: color,
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
            'Recent Signups',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No recent activity');
              }
              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final role = data['role'] as String? ?? 'user';
                  final title = '${role[0].toUpperCase()}${role.substring(1)} Account Created';
                  final name = data['firstName'] != null && data['lastName'] != null
                      ? '${data['firstName']} ${data['lastName']}'
                      : 'Unknown User';
                  final createdAt = data['createdAt'] as Timestamp?;
                  final dateStr = createdAt != null ? _formatDate(createdAt.toDate()) : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ActivityRow(
                      item: _ActivityItem(
                        title: title,
                        subtitle: name,
                        date: dateStr,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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

  void _openCreateStaff(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateStaffPage(selectedRole: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        label: 'Create Teacher Account',
        icon: Icons.person_add,
        onTap: () {
          _openCreateStaff(context, 'teacher');
        },
      ),
      _ActionItem(
        label: 'Create Trainer Account',
        icon: Icons.person_add_alt_1,
        onTap: () {
          _openCreateStaff(context, 'trainer');
        },
      ),
      const _ActionItem(label: 'Create Class', icon: Icons.class_rounded),
      const _ActionItem(label: 'Generate Report', icon: Icons.insert_chart),
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
  final VoidCallback? onTap;

  const _ActionItem({required this.label, required this.icon, this.onTap});
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});
  final _ActionItem action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
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
