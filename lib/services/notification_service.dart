import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications for current user - Fixed without orderBy
  Stream<List<NotificationModel>> getNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // Sort in memory instead of using orderBy
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Alternative: Get notifications with limit and no orderBy
  Stream<List<NotificationModel>> getNotificationsWithLimit({int limit = 20}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // Sort in memory
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Get unread count - Fixed without orderBy
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
      'readAt': FieldValue.serverTimestamp(),
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

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final data = notification.toFirestore();
      data['id'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['isRead'] = false;

      await docRef.set(data);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Send assignment notification
  Future<void> notifyNewAssignment(
      String classId, String assignmentTitle) async {
    try {
      final students = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      if (students.docs.isEmpty) return;

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');

      for (final student in students.docs) {
        final studentId = student.id;
        final docRef = notificationsRef.doc();

        batch.set(docRef, {
          'id': docRef.id,
          'userId': studentId,
          'title': 'New Assignment: $assignmentTitle',
          'message': 'A new assignment has been posted. Check it out!',
          'type': 'assignment',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending assignment notifications: $e');
    }
  }

  // Send quiz notification
  Future<void> notifyNewQuiz(String classId, String quizTitle) async {
    try {
      final students = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      if (students.docs.isEmpty) return;

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');

      for (final student in students.docs) {
        final studentId = student.id;
        final docRef = notificationsRef.doc();

        batch.set(docRef, {
          'id': docRef.id,
          'userId': studentId,
          'title': 'New Quiz: $quizTitle',
          'message': 'A new quiz is available. Take it now!',
          'type': 'quiz',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending quiz notifications: $e');
    }
  }

  // Send grade notification
  Future<void> notifyGrade(
      String studentId, String assignmentTitle, int score) async {
    try {
      await createNotification(
        NotificationModel(
          id: '',
          userId: studentId,
          title: 'Assignment Graded: $assignmentTitle',
          message: 'Your assignment has been graded. Score: $score/${100}',
          type: 'grade',
          referenceId: assignmentTitle,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      print('Error sending grade notification: $e');
    }
  }

  // Send custom notification to multiple users
  Future<void> sendBatchNotification({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    String? referenceId,
  }) async {
    try {
      if (userIds.isEmpty) return;

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');

      for (final userId in userIds) {
        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'id': docRef.id,
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'referenceId': referenceId ?? '',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error sending batch notifications: $e');
    }
  }
}
