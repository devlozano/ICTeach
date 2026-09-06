import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String content;
  final String? videoUrl;
  final String? attachmentUrl;
  final String? fileName;
  final String? cloudinaryPublicId;
  final String? cloudinaryResourceType;
  final String? fileFormat;
  final int? fileSize;
  final String? uploadedBy;
  final int order;
  final List<String> competencies;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModuleModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.content,
    this.videoUrl,
    this.attachmentUrl,
    this.fileName,
    this.cloudinaryPublicId,
    this.cloudinaryResourceType,
    this.fileFormat,
    this.fileSize,
    this.uploadedBy,
    required this.order,
    this.competencies = const [],
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModuleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ModuleModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? 'Untitled Module',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      videoUrl: data['videoUrl'],
      attachmentUrl: data['attachmentUrl'],
      fileName: data['fileName']?.toString(),
      cloudinaryPublicId: data['cloudinaryPublicId']?.toString(),
      cloudinaryResourceType: data['cloudinaryResourceType']?.toString(),
      fileFormat: data['fileFormat']?.toString(),
      fileSize: (data['fileSize'] as num?)?.toInt(),
      uploadedBy: data['uploadedBy']?.toString(),
      order: data['order'] ?? 0,
      competencies: List<String>.from(data['competencies'] ?? []),
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
      'content': content,
      'videoUrl': videoUrl,
      'attachmentUrl': attachmentUrl,
      'fileName': fileName,
      'cloudinaryPublicId': cloudinaryPublicId,
      'cloudinaryResourceType': cloudinaryResourceType,
      'fileFormat': fileFormat,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'order': order,
      'competencies': competencies,
      'isPublished': isPublished,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ Helper method to get video ID from YouTube URL
  String? get videoId {
    if (videoUrl == null || videoUrl!.isEmpty) return null;

    final url = videoUrl!;
    String videoId = '';

    if (url.contains('watch?v=')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    } else if (url.contains('m.youtube.com/watch')) {
      videoId = url.split('watch?v=').last.split('&').first;
    }

    return videoId.isNotEmpty ? videoId : null;
  }

  // ✅ Helper method to check if module has video
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  // ✅ Helper method to check if module has attachment
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  // ✅ Helper method to check if module is published
  bool get isPublishedAndAvailable => isPublished;

  // ✅ Helper method to get competency short names
  List<String> get competencyShortNames {
    return competencies.map((comp) {
      final parts = comp.split(':');
      return parts.isNotEmpty ? parts[0].trim() : comp;
    }).toList();
  }

  // ✅ Helper method to get full competency list with descriptions
  Map<String, String> get competencyMap {
    final map = <String, String>{};
    for (final comp in competencies) {
      final parts = comp.split(':');
      if (parts.length >= 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }
    return map;
  }

  // ✅ Helper method to check if module contains a specific competency
  bool hasCompetency(String competencyCode) {
    return competencies.any((comp) => comp.startsWith(competencyCode));
  }

  ModuleModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    String? content,
    String? videoUrl,
    String? attachmentUrl,
    String? fileName,
    String? cloudinaryPublicId,
    String? cloudinaryResourceType,
    String? fileFormat,
    int? fileSize,
    String? uploadedBy,
    int? order,
    List<String>? competencies,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuleModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      videoUrl: videoUrl ?? this.videoUrl,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      fileName: fileName ?? this.fileName,
      cloudinaryPublicId: cloudinaryPublicId ?? this.cloudinaryPublicId,
      cloudinaryResourceType:
          cloudinaryResourceType ?? this.cloudinaryResourceType,
      fileFormat: fileFormat ?? this.fileFormat,
      fileSize: fileSize ?? this.fileSize,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      order: order ?? this.order,
      competencies: competencies ?? this.competencies,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Factory method for creating an empty module (for UI placeholders)
  factory ModuleModel.empty() {
    return ModuleModel(
      id: '',
      classId: '',
      title: '',
      description: '',
      content: '',
      videoUrl: null,
      attachmentUrl: null,
      fileName: null,
      cloudinaryPublicId: null,
      cloudinaryResourceType: null,
      fileFormat: null,
      fileSize: null,
      uploadedBy: null,
      order: 0,
      competencies: const [],
      isPublished: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ✅ Convert to JSON for API calls (if needed)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'title': title,
      'description': description,
      'content': content,
      'videoUrl': videoUrl,
      'attachmentUrl': attachmentUrl,
      'fileName': fileName,
      'cloudinaryPublicId': cloudinaryPublicId,
      'cloudinaryResourceType': cloudinaryResourceType,
      'fileFormat': fileFormat,
      'fileSize': fileSize,
      'uploadedBy': uploadedBy,
      'order': order,
      'competencies': competencies,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ✅ Factory method from JSON (if needed)
  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      videoUrl: json['videoUrl'],
      attachmentUrl: json['attachmentUrl'],
      fileName: json['fileName']?.toString(),
      cloudinaryPublicId: json['cloudinaryPublicId']?.toString(),
      cloudinaryResourceType: json['cloudinaryResourceType']?.toString(),
      fileFormat: json['fileFormat']?.toString(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      uploadedBy: json['uploadedBy']?.toString(),
      order: json['order'] ?? 0,
      competencies: List<String>.from(json['competencies'] ?? []),
      isPublished: json['isPublished'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'ModuleModel(id: $id, title: $title, order: $order, isPublished: $isPublished)';
  }
}
