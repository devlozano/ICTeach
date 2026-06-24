import 'package:cloud_firestore/cloud_firestore.dart';

class QuizModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final List<Question> questions;
  final int timeLimit; // in minutes
  final int totalPoints;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    required this.questions,
    required this.timeLimit,
    required this.totalPoints,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuizModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return QuizModel(
      id: doc.id,
      classId: data['classId'] ?? '',
      title: data['title'] ?? 'Untitled Quiz',
      description: data['description'] ?? '',
      questions: (data['questions'] as List?)
              ?.map((q) => Question.fromMap(q))
              .toList() ??
          [],
      timeLimit: data['timeLimit'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
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
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimit': timeLimit,
      'totalPoints': totalPoints,
      'isPublished': isPublished,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  QuizModel copyWith({
    String? id,
    String? classId,
    String? title,
    String? description,
    List<Question>? questions,
    int? timeLimit,
    int? totalPoints,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizModel(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      timeLimit: timeLimit ?? this.timeLimit,
      totalPoints: totalPoints ?? this.totalPoints,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswer; // index of correct option (0-3)
  final String explanation;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswer: map['correctAnswer'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
    );
  }
}

// Quiz Result Model
class QuizResult {
  final String quizId;
  final String studentId;
  final String studentName;
  final int score;
  final int totalPoints;
  final List<UserAnswer> userAnswers;
  final DateTime completedAt;
  final int timeSpent; // in seconds

  QuizResult({
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.totalPoints,
    required this.userAnswers,
    required this.completedAt,
    required this.timeSpent,
  });

  factory QuizResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return QuizResult(
      quizId: data['quizId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      score: data['score'] ?? 0,
      totalPoints: data['totalPoints'] ?? 0,
      userAnswers: (data['userAnswers'] as List?)
              ?.map((a) => UserAnswer.fromMap(a))
              .toList() ??
          [],
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSpent: data['timeSpent'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'totalPoints': totalPoints,
      'userAnswers': userAnswers.map((a) => a.toMap()).toList(),
      'completedAt': FieldValue.serverTimestamp(),
      'timeSpent': timeSpent,
    };
  }

  double get percentage => totalPoints > 0 ? (score / totalPoints) * 100 : 0;
  bool get isPassed => percentage >= 60;
}

class UserAnswer {
  final String questionId;
  final int selectedAnswer; // index of selected option
  final bool isCorrect;
  final String correctAnswerText;
  final String explanation;

  UserAnswer({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.correctAnswerText,
    required this.explanation,
  });

  factory UserAnswer.fromMap(Map<String, dynamic> map) {
    return UserAnswer(
      questionId: map['questionId'] ?? '',
      selectedAnswer: map['selectedAnswer'] ?? 0,
      isCorrect: map['isCorrect'] ?? false,
      correctAnswerText: map['correctAnswerText'] ?? '',
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'correctAnswerText': correctAnswerText,
      'explanation': explanation,
    };
  }
}
