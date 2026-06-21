import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String content;
  final String? videoUrl;
  final int order;
  final List<String> competencies;
  final String? attachmentUrl; // ✅ Add this field
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;

  ModuleModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.content,
    this.videoUrl,
    required this.order,
    this.competencies = const [],
    this.attachmentUrl, // ✅ Add this
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
  });

  factory ModuleModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ModuleModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? 'Untitled Module',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      videoUrl: data['videoUrl'],
      order: data['order'] ?? 0,
      competencies: List<String>.from(data['competencies'] ?? []),
      attachmentUrl: data['attachmentUrl'], // ✅ Add this
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'content': content,
      'videoUrl': videoUrl,
      'order': order,
      'competencies': competencies,
      'attachmentUrl': attachmentUrl, // ✅ Add this
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ModuleModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? content,
    String? videoUrl,
    int? order,
    List<String>? competencies,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      order: order ?? this.order,
      competencies: competencies ?? this.competencies,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
