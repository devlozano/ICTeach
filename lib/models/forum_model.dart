// models/forum_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String classId;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole; // 'teacher', 'trainer', 'student'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final List<String> likedBy;
  final int viewCount;
  final int replyCount;

  ForumPost({
    required this.id,
    required this.classId,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.likedBy = const [],
    this.viewCount = 0,
    this.replyCount = 0,
  });

  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorRole: data['authorRole'] ?? 'student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      viewCount: data['viewCount'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'likedBy': likedBy,
      'viewCount': viewCount,
      'replyCount': replyCount,
    };
  }

  ForumPost copyWith({
    String? id,
    String? classId,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likeCount,
    List<String>? likedBy,
    int? viewCount,
    int? replyCount,
  }) {
    return ForumPost(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      viewCount: viewCount ?? this.viewCount,
      replyCount: replyCount ?? this.replyCount,
    );
  }
}

class ForumReply {
  final String id;
  final String postId;
  final String content;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likeCount;
  final List<String> likedBy;

  ForumReply({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    required this.updatedAt,
    this.likeCount = 0,
    this.likedBy = const [],
  });

  factory ForumReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id: doc.id,
      postId: data['postId'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorRole: data['authorRole'] ?? 'student',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'likedBy': likedBy,
    };
  }
}
