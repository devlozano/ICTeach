import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications for current user
  Stream<List<NotificationModel>> getNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    final docRef = _firestore.collection('notifications').doc();
    await docRef.set({
      ...notification.toFirestore(),
      'id': docRef.id,
    });
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Send assignment notification
  Future<void> notifyNewAssignment(
      String classId, String assignmentTitle) async {
    final students = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .get();

    for (final student in students.docs) {
      final studentId = student.id;
      await createNotification(
        NotificationModel(
          id: '',
          userId: studentId,
          title: 'New Assignment: $assignmentTitle',
          message: 'A new assignment has been posted. Check it out!',
          type: 'assignment',
          referenceId: classId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // Send quiz notification
  Future<void> notifyNewQuiz(String classId, String quizTitle) async {
    final students = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('students')
        .get();

    for (final student in students.docs) {
      final studentId = student.id;
      await createNotification(
        NotificationModel(
          id: '',
          userId: studentId,
          title: 'New Quiz: $quizTitle',
          message: 'A new quiz is available. Take it now!',
          type: 'quiz',
          referenceId: classId,
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  // Send grade notification
  Future<void> notifyGrade(
      String studentId, String assignmentTitle, int score) async {
    await createNotification(
      NotificationModel(
        id: '',
        userId: studentId,
        title: 'Assignment Graded: $assignmentTitle',
        message: 'Your assignment has been graded. Score: $score',
        type: 'grade',
        referenceId: assignmentTitle,
        createdAt: DateTime.now(),
      ),
    );
  }
}
