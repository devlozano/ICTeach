import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StudentQuestionnairesPage extends StatelessWidget {
  const StudentQuestionnairesPage({
    super.key,
    required this.classId,
    required this.className,
  });

  final String classId;
  final String className;

  Future<void> _answer(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> questionnaire,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = questionnaire.data();
    final questions = List<Map<String, dynamic>>.from(
      (data['questions'] as List? ?? const []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );
    final ratings = <String, double>{};
    final textControllers = <String, TextEditingController>{};
    for (final question in questions) {
      final id = question['id']?.toString() ?? '';
      if (question['type'] == 'rating') {
        ratings[id] = 3;
      } else {
        textControllers[id] = TextEditingController();
      }
    }

    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(data['title']?.toString() ?? 'Questionnaire'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['description']?.toString().isNotEmpty == true) ...[
                    Text(data['description'].toString()),
                    const SizedBox(height: 16),
                  ],
                  ...questions.map((question) {
                    final id = question['id']?.toString() ?? '';
                    final prompt = question['prompt']?.toString() ?? 'Question';
                    if (question['type'] == 'rating') {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prompt,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Row(
                              children: [
                                const Text('1'),
                                Expanded(
                                  child: Slider(
                                    value: ratings[id] ?? 3,
                                    min: 1,
                                    max: 5,
                                    divisions: 4,
                                    label: '${(ratings[id] ?? 3).round()}',
                                    onChanged: (value) => setDialogState(
                                      () => ratings[id] = value,
                                    ),
                                  ),
                                ),
                                const Text('5'),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: TextField(
                        controller: textControllers[id],
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: prompt,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit response'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || !context.mounted) return;

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final writtenAnswers = {
      for (final entry in textControllers.entries)
        entry.key: entry.value.text.trim(),
    };
    final summary = writtenAnswers.values
        .where((value) => value.isNotEmpty)
        .join(' • ');
    await FirebaseFirestore.instance
        .collection('questionnaire_responses')
        .doc('${questionnaire.id}_${user.uid}')
        .set({
          'classId': classId,
          'questionnaireId': questionnaire.id,
          'questionnaireTitle': data['title']?.toString() ?? 'Questionnaire',
          'questionnaireType': data['type']?.toString(),
          'studentId': user.uid,
          'studentName':
              userSnapshot.data()?['name']?.toString() ??
              user.email ??
              'Student',
          'ratings': ratings.map((key, value) => MapEntry(key, value.round())),
          'writtenAnswers': writtenAnswers,
          'summary': summary,
          'submittedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you. Your response was saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Questionnaires & Evaluations'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('questionnaires')
            .where('isPublished', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questionnaires = snapshot.data!.docs;
          if (questionnaires.isEmpty) {
            return const Center(
              child: Text('No questionnaire is open right now.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: questionnaires.length,
            itemBuilder: (context, index) {
              final questionnaire = questionnaires[index];
              final data = questionnaire.data();
              final responseId = '${questionnaire.id}_${user?.uid ?? ''}';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('questionnaire_responses')
                      .doc(responseId)
                      .get(),
                  builder: (context, responseSnapshot) {
                    final answered = responseSnapshot.data?.exists == true;
                    return ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: answered
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                        child: Icon(
                          answered
                              ? Icons.check_rounded
                              : Icons.rate_review_rounded,
                          color: answered ? Colors.green : Colors.blue,
                        ),
                      ),
                      title: Text(
                        data['title']?.toString() ?? 'Questionnaire',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        answered
                            ? 'Response submitted • tap to update'
                            : data['description']?.toString() ??
                                  'Tap to answer',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _answer(context, questionnaire),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
