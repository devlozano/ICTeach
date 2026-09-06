import 'package:flutter/material.dart';

/// Accessible horizontal bar chart with a fixed 0-100 percent scale.
class LeaderboardChart extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final String title;
  const LeaderboardChart({
    super.key,
    required this.entries,
    this.title = 'Quiz leaderboard',
  });
  @override
  Widget build(BuildContext context) {
    final ranked = entries.toList()
      ..sort(
        (a, b) => ((b['percentage'] as num?) ?? 0).compareTo(
          (a['percentage'] as num?) ?? 0,
        ),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (ranked.isEmpty) const Text('No scores yet.'),
        for (final entry in ranked.take(10).indexed) ...[
          Text(
            '${entry.$1 + 1}. ${entry.$2['studentName'] ?? 'Student'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label:
                      '${entry.$2['studentName']}: ${entry.$2['percentage']} percent',
                  child: LinearProgressIndicator(
                    minHeight: 16,
                    borderRadius: BorderRadius.circular(4),
                    value: (((entry.$2['percentage'] as num?) ?? 0) / 100)
                        .clamp(0.0, 1.0),
                    color: entry.$1 == 0
                        ? const Color(0xFFEAAE24)
                        : const Color(0xFF428DEB),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 46,
                child: Text(
                  '${((entry.$2['percentage'] as num?) ?? 0).round()}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        const Text(
          'Scale: 0-100% | Highest 10 scores',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
