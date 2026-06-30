import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications for current user
  Stream<List<NotificationModel>> getNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ getNotifications: No user logged in');
      return Stream.value([]);
    }

    print('✅ getNotifications: Fetching for user ${user.uid}');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      print('📬 getNotifications: Found ${snapshot.docs.length} notifications');
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Get unread count
  Stream<int> getUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ getUnreadCount: No user logged in');
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print('🔔 getUnreadCount: ${snapshot.docs.length} unread');
      return snapshot.docs.length;
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      print('✅ markAsRead: $notificationId');
    } catch (e) {
      print('❌ markAsRead error: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
      print('✅ markAllAsRead: ${snapshot.docs.length} notifications');
    } catch (e) {
      print('❌ markAllAsRead error: $e');
    }
  }

  // Create a notification
  Future<void> createNotification(NotificationModel notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final data = {
        'userId': notification.userId,
        'title': notification.title,
        'message': notification.message,
        'type': notification.type,
        'referenceId': notification.referenceId ?? '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      print('✅ createNotification: Created for user ${notification.userId}');
      print('   Title: ${notification.title}');
    } catch (e) {
      print('❌ createNotification error: $e');
    }
  }

  // ✅ FIXED: Forum notification - includes teacher, excludes poster
  Future<void> notifyNewForumPost(
    String classId,
    String postTitle,
    String authorName,
    String excludeUserId,
  ) async {
    try {
      print('📢 notifyNewForumPost: Starting for class $classId');

      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        print('❌ Class not found');
        return;
      }

      final classData = classDoc.data() as Map<String, dynamic>? ?? {};
      final enrolledIds =
          List<String>.from(classData['enrolledStudentIds'] ?? []);

      // ✅ ADD THE TEACHER TO THE LIST
      final teacherId = classData['teacherId']?.toString() ?? '';
      if (teacherId.isNotEmpty && !enrolledIds.contains(teacherId)) {
        enrolledIds.add(teacherId);
        print('📢 Added teacher to notification list: $teacherId');
      }

      // ✅ ADD TRAINERS FROM THE STUDENTS SUBCOLLECTION (they might be in there)
      final trainersSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('role', isEqualTo: 'trainer')
          .get();

      for (final doc in trainersSnapshot.docs) {
        final trainerId = doc.id;
        if (!enrolledIds.contains(trainerId)) {
          enrolledIds.add(trainerId);
          print('📢 Added trainer to notification list: $trainerId');
        }
      }

      print('📊 Found ${enrolledIds.length} total users to notify');

      if (enrolledIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;
      int skipped = 0;

      for (final userId in enrolledIds) {
        if (userId == excludeUserId) {
          skipped++;
          print('   ⏭️ Skipping poster: $userId');
          continue;
        }

        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) {
          print('   ⚠️ User document not found for: $userId');
          continue;
        }

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': userId,
          'title': '💬 New Forum Post: $postTitle',
          'message': '$authorName posted a new discussion in the forum.',
          'type': 'forum',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      print(
          '✅ notifyNewForumPost: Created $count notifications, skipped $skipped (poster)');
    } catch (e) {
      print('❌ notifyNewForumPost error: $e');
    }
  }

  // ✅ FIXED: Assignment notification - includes trainers, excludes teacher
  Future<void> notifyNewAssignment(
      String classId, String assignmentTitle) async {
    try {
      print('📢 notifyNewAssignment: Starting for class $classId');

      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        print('❌ Class not found');
        return;
      }

      final classData = classDoc.data() as Map<String, dynamic>? ?? {};
      final teacherId = classData['teacherId']?.toString() ?? '';
      final enrolledIds =
          List<String>.from(classData['enrolledStudentIds'] ?? []);

      // ✅ ADD TRAINERS FROM THE STUDENTS SUBCOLLECTION
      final trainersSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('role', isEqualTo: 'trainer')
          .get();

      for (final doc in trainersSnapshot.docs) {
        final trainerId = doc.id;
        if (!enrolledIds.contains(trainerId)) {
          enrolledIds.add(trainerId);
          print('📢 Added trainer to notification list: $trainerId');
        }
      }

      print('📊 Found ${enrolledIds.length} total users to notify');

      if (enrolledIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in enrolledIds) {
        if (userId == teacherId) {
          print('   ⏭️ Skipping teacher: $userId');
          continue;
        }

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': userId,
          'title': '📝 New Assignment: $assignmentTitle',
          'message': 'A new assignment has been posted. Check it out!',
          'type': 'assignment',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      print('✅ notifyNewAssignment: Created $count notifications');
    } catch (e) {
      print('❌ notifyNewAssignment error: $e');
    }
  }

  // ✅ FIXED: Quiz notification - includes trainers, excludes teacher
  Future<void> notifyNewQuiz(String classId, String quizTitle) async {
    try {
      print('📢 notifyNewQuiz: Starting for class $classId');

      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        print('❌ Class not found');
        return;
      }

      final classData = classDoc.data() as Map<String, dynamic>? ?? {};
      final teacherId = classData['teacherId']?.toString() ?? '';
      final enrolledIds =
          List<String>.from(classData['enrolledStudentIds'] ?? []);

      // ✅ ADD TRAINERS FROM THE STUDENTS SUBCOLLECTION
      final trainersSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('role', isEqualTo: 'trainer')
          .get();

      for (final doc in trainersSnapshot.docs) {
        final trainerId = doc.id;
        if (!enrolledIds.contains(trainerId)) {
          enrolledIds.add(trainerId);
          print('📢 Added trainer to notification list: $trainerId');
        }
      }

      print('📊 Found ${enrolledIds.length} total users to notify');

      if (enrolledIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in enrolledIds) {
        if (userId == teacherId) {
          print('   ⏭️ Skipping teacher: $userId');
          continue;
        }

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': userId,
          'title': '📝 New Quiz: $quizTitle',
          'message': 'A new quiz is available. Take it now!',
          'type': 'quiz',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      print('✅ notifyNewQuiz: Created $count notifications');
    } catch (e) {
      print('❌ notifyNewQuiz error: $e');
    }
  }

  // ✅ FIXED: Module notification - includes trainers, excludes teacher
  Future<void> notifyNewModule(String classId, String moduleTitle) async {
    try {
      print('📢 notifyNewModule: Starting for class $classId');

      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        print('❌ Class not found');
        return;
      }

      final classData = classDoc.data() as Map<String, dynamic>? ?? {};
      final teacherId = classData['teacherId']?.toString() ?? '';
      final enrolledIds =
          List<String>.from(classData['enrolledStudentIds'] ?? []);

      // ✅ ADD TRAINERS FROM THE STUDENTS SUBCOLLECTION
      final trainersSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .where('role', isEqualTo: 'trainer')
          .get();

      for (final doc in trainersSnapshot.docs) {
        final trainerId = doc.id;
        if (!enrolledIds.contains(trainerId)) {
          enrolledIds.add(trainerId);
          print('📢 Added trainer to notification list: $trainerId');
        }
      }

      print('📊 Found ${enrolledIds.length} total users to notify');

      if (enrolledIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in enrolledIds) {
        if (userId == teacherId) {
          print('   ⏭️ Skipping teacher: $userId');
          continue;
        }

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': userId,
          'title': '📚 New Module: $moduleTitle',
          'message':
              'A new learning module has been added. Start learning now!',
          'type': 'module',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
      }

      await batch.commit();
      print('✅ notifyNewModule: Created $count notifications');
    } catch (e) {
      print('❌ notifyNewModule error: $e');
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
          message: 'Your assignment has been graded. Score: $score/100',
          type: 'grade',
          referenceId: assignmentTitle,
          createdAt: DateTime.now(),
        ),
      );
      print('✅ notifyGrade: Sent to $studentId');
    } catch (e) {
      print('❌ notifyGrade error: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ deleteNotification: $notificationId');
    } catch (e) {
      print('❌ deleteNotification error: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ deleteAllNotifications: No user logged in');
        return;
      }

      print(
          '🗑️ deleteAllNotifications: Deleting all notifications for ${user.uid}');

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ deleteAllNotifications: No notifications to delete');
        return;
      }

      print(
          '📊 deleteAllNotifications: Found ${snapshot.docs.length} notifications to delete');

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print(
          '✅ deleteAllNotifications: Successfully deleted ${snapshot.docs.length} notifications');
    } catch (e) {
      print('❌ deleteAllNotifications error: $e');
      rethrow;
    }
  }

  // Check if user has any notifications
  Future<bool> hasNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ hasNotifications error: $e');
      return false;
    }
  }

  // Get notification count
  Future<int> getNotificationCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ getNotificationCount error: $e');
      return 0;
    }
  }
}
