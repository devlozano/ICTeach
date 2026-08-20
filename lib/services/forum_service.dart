// services/forum_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/forum_model.dart';
import 'notification_service.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get forum posts for a class
  Stream<List<ForumPost>> getForumPosts(String classId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ForumPost.fromFirestore(doc)).toList();
    });
  }

  // Get a single post with replies
  Future<ForumPost> getForumPost(String classId, String postId) async {
    final doc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .get();

    if (!doc.exists) {
      throw Exception('Post not found');
    }

    return ForumPost.fromFirestore(doc);
  }

  // Create a new forum post with notification
  Future<void> createPost(ForumPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get user role from users collection
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    String authorRole = userData['role']?.toString() ?? 'student';
    String authorName = userData['displayName']?.toString() ??
        userData['name']?.toString() ??
        user.displayName ??
        'Unknown';

    print('📝 Creating post - User: $authorName, Role: $authorRole');

    final postRef = _firestore
        .collection('classes')
        .doc(post.classId)
        .collection('forum_posts')
        .doc();

    final newPost = post.copyWith(
      id: postRef.id,
      authorName: authorName,
      authorRole: authorRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      likeCount: 0,
      likedBy: [],
      viewCount: 0,
      replyCount: 0,
    );

    await postRef.set(newPost.toFirestore());

    // ✅ Send notification to all users EXCEPT the poster
    await _notificationService.notifyNewForumPost(
      post.classId,
      post.title,
      authorName,
      user.uid,
    );

    // Debug: Check if notifications were created
    await _notificationService.debugClassUsers(post.classId);
  }

  // Like a post
  Future<void> toggleLikePost(String classId, String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId);

    final doc = await postRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final isLiked = likedBy.contains(user.uid);

    if (isLiked) {
      await postRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await postRef.update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String classId, String postId) async {
    final postRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId);

    await postRef.update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Get replies for a post
  Stream<List<ForumReply>> getReplies(String classId, String postId) {
    return _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ForumReply.fromFirestore(doc)).toList();
    });
  }

  // Add a reply with notification
  Future<void> addReply(String classId, String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get post to know the author
    final post = await getForumPost(classId, postId);

    // Get user role and name
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final authorRole = userData['role']?.toString() ?? 'student';
    final authorName = userData['displayName']?.toString() ??
        userData['name']?.toString() ??
        user.displayName ??
        'Unknown';

    final replyRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .collection('replies')
        .doc();

    final reply = ForumReply(
      id: replyRef.id,
      postId: postId,
      content: content,
      authorId: user.uid,
      authorName: authorName,
      authorRole: authorRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      likeCount: 0,
      likedBy: [],
    );

    await replyRef.set(reply.toFirestore());

    // Update reply count on post
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .update({
      'replyCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ✅ Send notification to all users in class EXCEPT the replier
    await _notificationService.notifyNewForumReply(
      classId,
      post.title,
      authorName,
      post.authorId,
      user.uid,
    );

    print('✅ Reply notification sent for post: ${post.title}');
  }

  // Like a reply
  Future<void> toggleLikeReply(
      String classId, String postId, String replyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final replyRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .collection('replies')
        .doc(replyId);

    final doc = await replyRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final likedBy = List<String>.from(data['likedBy'] ?? []);
    final isLiked = likedBy.contains(user.uid);

    if (isLiked) {
      await replyRef.update({
        'likedBy': FieldValue.arrayRemove([user.uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await replyRef.update({
        'likedBy': FieldValue.arrayUnion([user.uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  // Delete a post (only by author or teacher)
  Future<void> deletePost(String classId, String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if user is author or teacher
    final post = await getForumPost(classId, postId);
    if (post.authorId != user.uid) {
      // Check if user is teacher
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final role = userData['role']?.toString() ?? 'student';
      if (role != 'teacher' && role != 'trainer') {
        throw Exception('Only the author or teacher can delete this post');
      }
    }

    // Delete all replies first
    final repliesSnapshot = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .collection('replies')
        .get();

    final batch = _firestore.batch();
    for (final doc in repliesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the post
    final postRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId);
    batch.delete(postRef);

    await batch.commit();
  }
}
