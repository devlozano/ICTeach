import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/assignment_model.dart';

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all assignments for a class
  Stream<List<AssignmentModel>> getAssignmentsForClass(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AssignmentModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get published assignments for students
  Stream<List<AssignmentModel>> getPublishedAssignmentsForClass(
      String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .where('isPublished', isEqualTo: true)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AssignmentModel.fromFirestore(doc))
          .toList();
    });
  }

  // Create a new assignment
  Future<void> createAssignment(AssignmentModel assignment) async {
    final docRef = _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc();

    await docRef.set({
      ...assignment.toFirestore(),
      'id': docRef.id,
    });
  }

  // Update an assignment
  Future<void> updateAssignment(AssignmentModel assignment) async {
    await _firestore
        .collection('classes')
        .doc(assignment.classId)
        .collection('assignments')
        .doc(assignment.id)
        .update(assignment.toFirestore());
  }

  // Delete an assignment
  Future<void> deleteAssignment(String classId, String assignmentId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .delete();
  }

  // Toggle publish status
  Future<void> togglePublish(
      String classId, String assignmentId, bool isPublished) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('assignments')
        .doc(assignmentId)
        .update({
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Submit assignment
  Future<void> submitAssignment(AssignmentSubmission submission) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore
        .collection('classes')
        .doc(submission.assignmentId) // We'll need to store classId separately
        .collection('submissions')
        .doc('${submission.assignmentId}_${user.uid}')
        .set(submission.toFirestore());
  }

  // Get student's submission for an assignment
  Future<AssignmentSubmission?> getStudentSubmission(
      String assignmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('submissions')
        .doc('${assignmentId}_${user.uid}')
        .get();

    if (doc.exists) {
      return AssignmentSubmission.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  // Get all submissions for an assignment (teacher view)
  Future<List<AssignmentSubmission>> getSubmissionsForAssignment(
      String assignmentId) async {
    final snapshot = await _firestore
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('submittedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AssignmentSubmission.fromFirestore(doc))
        .toList();
  }

  // Grade a submission
  Future<void> gradeSubmission(
      String submissionId, int score, String feedback) async {
    await _firestore.collection('submissions').doc(submissionId).update({
      'score': score,
      'feedback': feedback,
      'isGraded': true,
    });
  }

  // Check if student has submitted
  Future<bool> hasSubmitted(String assignmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore
        .collection('submissions')
        .doc('${assignmentId}_${user.uid}')
        .get();

    return doc.exists;
  }
}
