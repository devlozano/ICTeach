import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final DateTime dueDate;
  final int maxScore;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.maxScore,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AssignmentModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? 'Untitled Assignment',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxScore: data['maxScore'] ?? 100,
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'maxScore': maxScore,
      'isPublished': isPublished,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? maxScore,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      maxScore: maxScore ?? this.maxScore,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Assignment Submission Model
class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String studentName;
  final String content;
  final String? attachmentUrl;
  final int score;
  final String? feedback;
  final DateTime submittedAt;
  final bool isGraded;

  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.studentName,
    required this.content,
    this.attachmentUrl,
    required this.score,
    this.feedback,
    required this.submittedAt,
    required this.isGraded,
  });

  factory AssignmentSubmission.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AssignmentSubmission(
      id: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Student',
      content: data['content'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      score: data['score'] ?? 0,
      feedback: data['feedback'],
      submittedAt:
          (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGraded: data['isGraded'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'studentName': studentName,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'score': score,
      'feedback': feedback,
      'submittedAt': FieldValue.serverTimestamp(),
      'isGraded': isGraded,
    };
  }

  AssignmentSubmission copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? studentName,
    String? content,
    String? attachmentUrl,
    int? score,
    String? feedback,
    DateTime? submittedAt,
    bool? isGraded,
  }) {
    return AssignmentSubmission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      content: content ?? this.content,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      score: score ?? this.score,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      isGraded: isGraded ?? this.isGraded,
    );
  }
}
