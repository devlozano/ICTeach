import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_model.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all quizzes for a class
  Stream<List<QuizModel>> getQuizzesForClass(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .snapshots()
        .map((snapshot) {
      final quizzes =
          snapshot.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quizzes;
    });
  }

  // ✅ FIXED: Get published quizzes for students (no index needed)
  Stream<List<QuizModel>> getPublishedQuizzesForClass(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final quizzes =
          snapshot.docs.map((doc) => QuizModel.fromFirestore(doc)).toList();
      // ✅ Sort in memory by createdAt (descending)
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quizzes;
    });
  }

  // Create a new quiz
  Future<void> createQuiz(QuizModel quiz) async {
    final docRef = _firestore
        .collection('classes')
        .doc(quiz.classId)
        .collection('quizzes')
        .doc();

    await docRef.set({
      ...quiz.toFirestore(),
      'id': docRef.id,
    });
  }

  // Update an existing quiz
  Future<void> updateQuiz(QuizModel quiz) async {
    await _firestore
        .collection('classes')
        .doc(quiz.classId)
        .collection('quizzes')
        .doc(quiz.id)
        .update(quiz.toFirestore());
  }

  // Delete a quiz
  Future<void> deleteQuiz(String classId, String quizId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .delete();
  }

  // Get a single quiz by ID
  Future<QuizModel?> getQuiz(String classId, String quizId) async {
    final doc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .get();

    if (doc.exists) {
      return QuizModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  // Toggle publish status
  Future<void> togglePublish(
      String classId, String quizId, bool isPublished) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('quizzes')
        .doc(quizId)
        .update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check if student has already taken a quiz
  Future<bool> hasTakenQuiz(String studentId, String quizId) async {
    try {
      if (studentId.isEmpty) {
        return false;
      }
      final doc = await _firestore
          .collection('users')
          .doc(studentId)
          .collection('quiz_results')
          .doc(quizId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking quiz status: $e');
      return false;
    }
  }

  // Save quiz result
  Future<void> saveQuizResult(QuizResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .doc(result.quizId)
        .set(result.toFirestore());

    await _firestore
        .collection('quiz_results')
        .doc('${result.quizId}_${user.uid}')
        .set(result.toFirestore());
  }

  // Get quiz results for a student
  Future<List<QuizResult>> getStudentQuizResults(String studentId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(studentId)
        .collection('quiz_results')
        .orderBy('completedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => QuizResult.fromFirestore(doc)).toList();
  }

  // Get quiz results for a specific quiz (teacher view)
  Future<List<QuizResult>> getQuizResults(String classId, String quizId) async {
    final snapshot = await _firestore
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .orderBy('score', descending: true)
        .get();

    return snapshot.docs.map((doc) => QuizResult.fromFirestore(doc)).toList();
  }

  // Get quiz attempt count
  Future<int> getQuizAttemptCount(String quizId) async {
    final snapshot = await _firestore
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .get();

    return snapshot.docs.length;
  }
}
