// services/notification_service.dart
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

  // ✅ FIXED: Get ALL users in class (students, trainers, and teacher)
  Future<List<String>> _getAllUsersInClass(String classId) async {
    final List<String> allUserIds = [];
    final Set<String> uniqueIds = {};

    try {
      print('🔍 Getting all users for class: $classId');

      // Get the class document
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (!classDoc.exists) {
        print('❌ Class not found');
        return allUserIds;
      }

      final classData = classDoc.data() as Map<String, dynamic>? ?? {};

      // 1. Add teacher
      final teacherId = classData['teacherId']?.toString() ?? '';
      if (teacherId.isNotEmpty && !uniqueIds.contains(teacherId)) {
        uniqueIds.add(teacherId);
        allUserIds.add(teacherId);
        print('📢 Added teacher: $teacherId');
      }

      // 2. Add all enrolled students from the array
      final enrolledIds =
          List<String>.from(classData['enrolledStudentIds'] ?? []);
      print('📊 enrolledStudentIds array: ${enrolledIds.length} users');
      for (final userId in enrolledIds) {
        if (!uniqueIds.contains(userId)) {
          uniqueIds.add(userId);
          allUserIds.add(userId);
          print('   Added from enrolledStudentIds: $userId');
        }
      }

      // 3. Also check students subcollection for any additional users
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      print('📊 students subcollection: ${studentsSnapshot.docs.length} users');
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? doc.id;
        if (!uniqueIds.contains(uid)) {
          uniqueIds.add(uid);
          allUserIds.add(uid);
          print(
              '   Added from students subcollection: $uid (Name: ${data['name']})');
        }
      }

      // 4. Check if there's a separate trainers collection
      final trainersSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('trainers')
          .get();

      for (final doc in trainersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? doc.id;
        if (!uniqueIds.contains(uid)) {
          uniqueIds.add(uid);
          allUserIds.add(uid);
          print('   Added from trainers subcollection: $uid');
        }
      }

      // 5. Verify all users exist in users collection and get their roles
      final List<String> validUserIds = [];
      for (final userId in allUserIds) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            validUserIds.add(userId);
            final userData = userDoc.data() as Map<String, dynamic>? ?? {};
            final role = userData['role']?.toString() ?? 'student';
            final name = userData['displayName'] ?? userData['name'] ?? userId;
            print('   ✅ Valid user: $name (Role: $role, ID: $userId)');
          } else {
            print('   ⚠️ User document not found for: $userId');
            // Still add the user to ensure notifications are sent
            validUserIds.add(userId);
          }
        } catch (e) {
          print('   ⚠️ Error checking user $userId: $e');
          // Add the user anyway to not miss notifications
          validUserIds.add(userId);
        }
      }

      print('📊 Total valid users in class: ${validUserIds.length}');
      print('📊 Final user list: $validUserIds');

      return validUserIds;
    } catch (e) {
      print('❌ Error getting users: $e');
      return allUserIds;
    }
  }

  // ✅ Get only STUDENT users in class (excludes teacher and trainer roles)
  Future<List<String>> _getStudentUsersInClass(String classId) async {
    final allUserIds = await _getAllUsersInClass(classId);
    final List<String> studentIds = [];

    for (final userId in allUserIds) {
      try {
        final userDoc =
            await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() as Map<String, dynamic>? ?? {};
        final role = userData['role']?.toString().toLowerCase() ?? '';

        if (role == 'teacher' || role == 'trainer') {
          print('   ⏭️ Skipping $role: $userId');
          continue;
        }
        studentIds.add(userId);
      } catch (e) {
        print('   ⚠️ Could not fetch role for $userId, skipping: $e');
      }
    }

    print('📊 Student-only list: ${studentIds.length} students');
    return studentIds;
  }


  // ✅ Send forum post notification to ALL users
  Future<void> notifyNewForumPost(
    String classId,
    String postTitle,
    String authorName,
    String excludeUserId,
  ) async {
    try {
      print('📢 notifyNewForumPost: Starting for class $classId');
      print('📢 Author: $authorName, Excluding: $excludeUserId');

      final allUserIds = await _getAllUsersInClass(classId);

      if (allUserIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in allUserIds) {
        if (userId == excludeUserId) {
          print('   ⏭️ Skipping poster: $userId');
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
        print('   ✅ Added notification for user: $userId');
      }

      await batch.commit();
      print('✅ notifyNewForumPost: Created $count notifications');
    } catch (e) {
      print('❌ notifyNewForumPost error: $e');
    }
  }

  // ✅ Send forum reply notification to ALL users
  Future<void> notifyNewForumReply(
    String classId,
    String postTitle,
    String replyAuthor,
    String postAuthorId,
    String excludeUserId,
  ) async {
    try {
      print('📢 notifyNewForumReply: Starting for class $classId');
      print(
          '📢 Reply author: $replyAuthor, Post author: $postAuthorId, Excluding: $excludeUserId');

      final allUserIds = await _getAllUsersInClass(classId);

      if (allUserIds.isEmpty) {
        print('⚠️ No users found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in allUserIds) {
        if (userId == excludeUserId) {
          print('   ⏭️ Skipping replier: $userId');
          continue;
        }

        String message;
        if (userId == postAuthorId) {
          message = '$replyAuthor replied to your post: "$postTitle"';
        } else {
          message = '$replyAuthor replied to a discussion: "$postTitle"';
        }

        final docRef = notificationsRef.doc();
        batch.set(docRef, {
          'userId': userId,
          'title': '💬 New Reply in Forum',
          'message': message,
          'type': 'forum',
          'referenceId': classId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        count++;
        print('   ✅ Added reply notification for user: $userId');
      }

      await batch.commit();
      print('✅ notifyNewForumReply: Created $count notifications');
    } catch (e) {
      print('❌ notifyNewForumReply error: $e');
    }
  }

  // ✅ Send assignment notification to students only (skip teacher and trainers)
  Future<void> notifyNewAssignment(
      String classId, String assignmentTitle) async {
    try {
      print('📢 notifyNewAssignment: Starting for class $classId');

      final studentIds = await _getStudentUsersInClass(classId);

      if (studentIds.isEmpty) {
        print('⚠️ No students found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in studentIds) {
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
        print('   ✅ Added assignment notification for student: $userId');
      }

      await batch.commit();
      print('✅ notifyNewAssignment: Created $count notifications (students only)');
    } catch (e) {
      print('❌ notifyNewAssignment error: $e');
    }
  }

  // ✅ Send quiz notification to students only (skip teacher and trainers)
  Future<void> notifyNewQuiz(String classId, String quizTitle) async {
    try {
      print('📢 notifyNewQuiz: Starting for class $classId');

      final studentIds = await _getStudentUsersInClass(classId);

      if (studentIds.isEmpty) {
        print('⚠️ No students found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in studentIds) {
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
        print('   ✅ Added quiz notification for student: $userId');
      }

      await batch.commit();
      print('✅ notifyNewQuiz: Created $count notifications (students only)');
    } catch (e) {
      print('❌ notifyNewQuiz error: $e');
    }
  }

  // ✅ Send module notification to students only (skip teacher and trainers)
  Future<void> notifyNewModule(String classId, String moduleTitle) async {
    try {
      print('📢 notifyNewModule: Starting for class $classId');

      final studentIds = await _getStudentUsersInClass(classId);

      if (studentIds.isEmpty) {
        print('⚠️ No students found in class');
        return;
      }

      final batch = _firestore.batch();
      final notificationsRef = _firestore.collection('notifications');
      int count = 0;

      for (final userId in studentIds) {
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
        print('   ✅ Added module notification for student: $userId');
      }

      await batch.commit();
      print('✅ notifyNewModule: Created $count notifications (students only)');
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

  // ✅ Debug method to check class users
  Future<void> debugClassUsers(String classId) async {
    try {
      print('🔍 ===== DEBUG: Checking all users in class $classId =====');

      // Get class document
      final classDoc =
          await _firestore.collection('classes').doc(classId).get();
      if (classDoc.exists) {
        final data = classDoc.data() as Map<String, dynamic>? ?? {};
        print('📚 Class: ${data['name']}');
        print('👨‍🏫 Teacher: ${data['teacherId']}');

        final enrolledIds = List<String>.from(data['enrolledStudentIds'] ?? []);
        print('📊 enrolledStudentIds: ${enrolledIds.length}');
        for (final id in enrolledIds) {
          final userDoc = await _firestore.collection('users').doc(id).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>? ?? {};
            print(
                '   ✅ Student: ${userData['displayName'] ?? userData['name'] ?? id}');
          } else {
            print('   ❌ User not found: $id');
          }
        }
      }

      // Check students subcollection
      final studentsSnapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      print('📊 students subcollection: ${studentsSnapshot.docs.length}');
      for (final doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final uid = data['uid']?.toString() ?? doc.id;
        final name = data['name']?.toString() ?? 'Unknown';
        final role = data['role']?.toString() ?? 'student';
        print('   👤 $name (UID: $uid, Role: $role)');
      }

      print('🔍 ===== DEBUG COMPLETE =====');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
}
