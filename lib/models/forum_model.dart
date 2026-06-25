import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String classId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final List<ForumReply> replies;
  final DateTime createdAt;
  final DateTime updatedAt;

  ForumPost({
    required this.id,
    required this.classId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.replies,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ForumPost.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ForumPost(
      id: doc.id,
      classId: data['classId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      title: data['title'] ?? 'Untitled',
      content: data['content'] ?? '',
      replies: (data['replies'] as List?)
              ?.map((r) => ForumReply.fromMap(r))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'authorId': authorId,
      'authorName': authorName,
      'title': title,
      'content': content,
      'replies': replies.map((r) => r.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ForumReply {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  ForumReply({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

// In ForumReply class
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt), // ✅ Fixed: Use Timestamp
    };
  }

// In ForumReply factory
  factory ForumReply.fromMap(Map<String, dynamic> map) {
    return ForumReply(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? 'Unknown',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
