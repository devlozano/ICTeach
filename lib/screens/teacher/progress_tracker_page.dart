import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

class ProgressTrackerPage extends StatefulWidget {
  final String classId;
  final String className;

  const ProgressTrackerPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage> {
  final QuizService _quizService = QuizService();

  Widget _buildLeaderboardItem(
    int index,
    String name,
    int score,
    int quizzesTaken,
    Color color,
  ) {
    String rankBadge;
    if (index == 0) rankBadge = '🥇';
    else if (index == 1) rankBadge = '🥈';
    else if (index == 2) rankBadge = '🥉';
    else rankBadge = '${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: index < 3 ? Border.all(color: color.withOpacity(0.5), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: index < 3
                  ? LinearGradient(
                      colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: index >= 3 ? const Color(0xFFF1F5F9) : null,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              rankBadge,
              style: TextStyle(
                fontSize: index < 3 ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: index < 3 ? null : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quizzes Completed: $quizzesTaken',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$score%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLeaderboardChart(List<QuizResult> results) {
    if (results.isEmpty) return const SizedBox.shrink();

    // Group by student
    final Map<String, List<QuizResult>> studentResults = {};
    for (final result in results) {
      studentResults.putIfAbsent(result.studentId, () => []).add(result);
    }

    // Calculate averages
    final studentAverages = studentResults.entries.map((entry) {
      final avg = entry.value.fold<double>(0, (sum, r) => sum + r.percentage) /
          entry.value.length;
      return {
        'name': entry.value.first.studentName,
        'average': avg,
      };
    }).toList()
      ..sort((a, b) =>
          (b['average'] as double).compareTo(a['average'] as double));

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: 100,
          barGroups: studentAverages.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data['average'] as double,
                  color: index == 0 ? Colors.amber : Colors.blue,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < studentAverages.length) {
                    return Text(
                      studentAverages[index]['name'] as String,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%');
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _quizService.getClassLeaderboard(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final leaderboard = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0B2B4A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B2B4A), Color(0xFF168D92)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Icon(
                            Icons.emoji_events_rounded,
                            size: 200,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'CLASS LEADERBOARD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.className,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${leaderboard.length} Active Students',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (leaderboard.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No Progress Data',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No quiz results found for this class.',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = leaderboard[index];
                        final color = index == 0
                            ? const Color(0xFFFFB800) // Gold
                            : index == 1
                                ? const Color(0xFF94A3B8) // Silver
                                : index == 2
                                    ? const Color(0xFFCD7F32) // Bronze
                                    : const Color(0xFF168D92); // Default brand

                        return _buildLeaderboardItem(
                          index,
                          data['studentName'] as String,
                          data['percentage'] as int,
                          data['quizCount'] as int,
                          color,
                        );
                      },
                      childCount: leaderboard.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

