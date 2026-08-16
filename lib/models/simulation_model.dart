import 'package:cloud_firestore/cloud_firestore.dart';

class DraggableItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String correctSlot;
  final String category;

  DraggableItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.correctSlot,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'correctSlot': correctSlot,
        'category': category,
      };

  factory DraggableItem.fromJson(Map<String, dynamic> json) => DraggableItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        correctSlot: json['correctSlot']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
      );
}

class Simulation {
  final String id;
  final String title;
  final String description;
  final String type;
  final String competency;
  final String learningOutcome;
  final List<DraggableItem> items;
  final List<String> slots;
  final int timeLimit;
  final int passingScore;
  final bool isPublished;
  final bool isLocked;
  final String? requiredSimulationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Simulation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.competency,
    required this.learningOutcome,
    required this.items,
    required this.slots,
    required this.timeLimit,
    required this.passingScore,
    required this.isPublished,
    required this.isLocked,
    this.requiredSimulationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Simulation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final itemsData = data['items'] as List? ?? [];
    final items = itemsData
        .map((item) => DraggableItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return Simulation(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      type: data['type']?.toString() ?? 'assembly',
      competency: data['competency']?.toString() ?? 'COC1',
      learningOutcome: data['learningOutcome']?.toString() ?? 'LO1',
      items: items,
      slots: List<String>.from(data['slots'] ?? []),
      timeLimit: data['timeLimit'] is int ? data['timeLimit'] : 0,
      passingScore: data['passingScore'] is int ? data['passingScore'] : 70,
      isPublished: data['isPublished'] ?? false,
      isLocked: data['isLocked'] ?? false,
      requiredSimulationId: data['requiredSimulationId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'competency': competency,
      'learningOutcome': learningOutcome,
      'items': items.map((i) => i.toJson()).toList(),
      'slots': slots,
      'timeLimit': timeLimit,
      'passingScore': passingScore,
      'isPublished': isPublished,
      'isLocked': isLocked,
      'requiredSimulationId': requiredSimulationId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
