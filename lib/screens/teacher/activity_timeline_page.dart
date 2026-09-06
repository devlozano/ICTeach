import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/content_access_service.dart';

class ActivityTimelinePage extends StatefulWidget {
  final String classId;
  const ActivityTimelinePage({super.key, required this.classId});
  @override
  State<ActivityTimelinePage> createState() => _ActivityTimelinePageState();
}

class _ActivityTimelinePageState extends State<ActivityTimelinePage> {
  late final _staff = ContentAccessService.isClassStaff(widget.classId);
  late final _events = FirebaseFirestore.instance
      .collection('activity_events')
      .where('classId', isEqualTo: widget.classId)
      .snapshots();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student activity timeline')),
    body: FutureBuilder<bool>(
      future: _staff,
      builder: (context, staff) {
        if (staff.hasError || staff.data == false)
          return const Center(
            child: Text('Class teacher/trainer access required.'),
          );
        if (!staff.hasData)
          return const Center(child: CircularProgressIndicator());
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _events,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Center(
                child: Text(
                  'Unable to load activity. Check connection and permissions.',
                ),
              );
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final events = snapshot.data!.docs.toList()
              ..sort(
                (a, b) =>
                    ((b.data()['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0)
                        .compareTo(
                          (a.data()['createdAt'] as Timestamp?)
                                  ?.millisecondsSinceEpoch ??
                              0,
                        ),
              );
            if (events.isEmpty)
              return const Center(
                child: Text(
                  'No activity recorded yet. New lesson, practice and assessment events appear here.',
                ),
              );
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index].data();
                final date = (e['createdAt'] as Timestamp?)?.toDate().toLocal();
                return ExpansionTile(
                  title: Text(
                    '${e['studentName'] ?? e['studentId']} • ${e['title'] ?? e['contentId']}',
                  ),
                  subtitle: Text(
                    '${e['event']} • ${e['mode'] ?? 'learning'} • ${date ?? 'syncing'}',
                  ),
                  children: [
                    if (e['score'] != null)
                      ListTile(
                        title: Text('Score: ${e['score']} / ${e['total']}'),
                      ),
                    ...((e['errors'] as List?) ?? []).map(
                      (error) => ListTile(
                        leading: const Icon(Icons.build),
                        title: Text('$error'),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Practice is ungraded. A recorded completion is not a physical competency certificate.',
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    ),
  );
}
