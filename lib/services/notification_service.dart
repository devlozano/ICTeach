import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get notifications for current user - Fixed without orderBy
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
  // Add these methods to your NotificationService class

// Debug: Check all classes for the current teacher
  Future<void> debugAllClasses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }

      print('🔍 ===== DEBUG: Checking all classes for teacher =====');
      print('👤 Teacher UID: ${user.uid}');
      print('📧 Teacher Email: ${user.email}');

      // Get all classes for this teacher
      final classesSnapshot = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: user.uid)
          .get();

      print('📊 Found ${classesSnapshot.docs.length} classes');

      if (classesSnapshot.docs.isEmpty) {
        print('⚠️ No classes found for this teacher');
        return;
      }

      for (final classDoc in classesSnapshot.docs) {
        final classId = classDoc.id;
        final classData = classDoc.data();
        final className = classData['className'] ?? 'Unnamed Class';

        print('\n📚 Class: $className (ID: $classId)');
        print('   Teacher ID: ${classData['teacherId']}');

        // Check students in this class
        await debugClassStudents(classId);
      }

      print('\n🔍 ===== DEBUG COMPLETE =====');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

// Debug: Check students in a specific class
  Future<void> debugClassStudents(String classId) async {
    try {
      print('   📋 Checking students for class: $classId');

      // Method 1: Check subcollection
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      print('   📊 Students in subcollection: ${studentsSnapshot.docs.length}');

      if (studentsSnapshot.docs.isNotEmpty) {
        for (final doc in studentsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          print('      👤 Student ID: ${doc.id}');
          print('         Name: ${data['name'] ?? 'Unknown'}');
          print('         UID: ${data['uid'] ?? 'Not set'}');
          print('         Email: ${data['email'] ?? 'Not set'}');
          print('         Data: ${data.keys.join(', ')}');
        }
      }

      // Method 2: Check if students are in the class document
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        final classData = classDoc.data() as Map<String, dynamic>? ?? {};
        final enrolledStudents = classData['enrolledStudentIds'] as List? ?? [];
        print('   📊 enrolledStudentIds array: ${enrolledStudents.length}');
        if (enrolledStudents.isNotEmpty) {
          print('      Students: ${enrolledStudents.join(', ')}');
        }
      }

      print('   ✅ Class debug complete');
    } catch (e) {
      print('   ❌ Error debugging class: $e');
    }
  }

// Debug: Check notifications for a specific user
  Future<void> debugUserNotifications(String userId) async {
    try {
      print('🔍 ===== DEBUG: Checking notifications for user $userId =====');

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      print('📊 Found ${snapshot.docs.length} notifications');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('   📬 Notification: ${data['title']}');
        print('      Type: ${data['type']}');
        print('      Read: ${data['isRead']}');
        print('      Created: ${data['createdAt']}');
      }

      print('🔍 ===== DEBUG COMPLETE =====');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

// Debug: Check if a notification exists for a class
  Future<void> debugClassNotifications(String classId) async {
    try {
      print('🔍 ===== DEBUG: Checking notifications for class $classId =====');

      final snapshot = await _firestore
          .collection('notifications')
          .where('referenceId', isEqualTo: classId)
          .get();

      print('📊 Found ${snapshot.docs.length} notifications for this class');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('   📬 Notification: ${data['title']}');
        print('      User: ${data['userId']}');
        print('      Type: ${data['type']}');
        print('      Read: ${data['isRead']}');
      }

      print('🔍 ===== DEBUG COMPLETE =====');
    } catch (e) {
      print('❌ Debug error: $e');
    }
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

  // ✅ FIXED: Send assignment notification to ALL students in class
  Future<void> notifyNewAssignment(
      String classId, String assignmentTitle) async {
    try {
      print('📢 notifyNewAssignment: Starting for class $classId');

      // Get all students in the class
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      print('📊 Found ${studentsSnapshot.docs.length} students');

      if (studentsSnapshot.docs.isEmpty) {
        print('⚠️ No students found in class');
        return;
      }

      // Create notifications for each student
      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        // Also check if studentId is in the data
        final data = studentDoc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? studentId;

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': uid,
          'title': 'New Assignment: $assignmentTitle',
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
      // Don't throw - we don't want to break the assignment creation
    }
  }

  // Send quiz notification
  Future<void> notifyNewQuiz(String classId, String quizTitle) async {
    try {
      print('📢 notifyNewQuiz: Starting for class $classId');

      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      print('📊 Found ${studentsSnapshot.docs.length} students');

      if (studentsSnapshot.docs.isEmpty) {
        print('⚠️ No students found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final data = studentDoc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? studentId;

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': uid,
          'title': 'New Quiz: $quizTitle',
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

  // In notification_service.dart
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

      // Get all notifications for the user
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

      // Use batch delete for better performance
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print(
          '✅ deleteAllNotifications: Successfully deleted ${snapshot.docs.length} notifications');
    } catch (e) {
      print('❌ deleteAllNotifications error: $e');
      rethrow; // Re-throw to be caught by the caller
    }
  }

  // In notification_service.dart
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
