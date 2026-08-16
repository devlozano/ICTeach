import 'package:cloud_firestore/cloud_firestore.dart';

class ContentLock {
  final String id;
  final String classId;
  final String contentType; // 'practice', 'simulation', 'module'
  final String contentId;
  final bool isLocked;
  final String? requiredContentId; // What needs to be completed first
  final DateTime? unlockDate;

  ContentLock({
    required this.id,
    required this.classId,
    required this.contentType,
    required this.contentId,
    required this.isLocked,
    this.requiredContentId,
    this.unlockDate,
  });

  factory ContentLock.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentLock(
      id: doc.id,
      classId: data['classId'] ?? '',
      contentType: data['contentType'] ?? '',
      contentId: data['contentId'] ?? '',
      isLocked: data['isLocked'] ?? false,
      requiredContentId: data['requiredContentId'],
      unlockDate: (data['unlockDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'contentType': contentType,
      'contentId': contentId,
      'isLocked': isLocked,
      'requiredContentId': requiredContentId,
      'unlockDate': unlockDate,
    };
  }
}
