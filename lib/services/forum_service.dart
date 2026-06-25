import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/forum_model.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all forum posts for a class
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

  // Create a new forum post
  Future<void> createPost(ForumPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = _firestore
        .collection('classes')
        .doc(post.classId)
        .collection('forum_posts')
        .doc();

    await docRef.set({
      ...post.toFirestore(),
      'id': docRef.id,
    });
  }

// Add a reply to a post
  Future<void> addReply(String classId, String postId, ForumReply reply) async {
    try {
      // ✅ FIXED: Use arrayUnion to safely add the reply
      await _firestore
          .collection('classes')
          .doc(classId)
          .collection('forum_posts')
          .doc(postId)
          .update({
        'replies': FieldValue.arrayUnion([reply.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding reply: $e');
      rethrow;
    }
  }

  // Get a single post
  Future<ForumPost?> getPost(String classId, String postId) async {
    final doc = await _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .get();

    if (doc.exists) {
      return ForumPost.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>);
    }
    return null;
  }

  // Delete a post
  Future<void> deletePost(String classId, String postId) async {
    await _firestore
        .collection('classes')
        .doc(classId)
        .collection('forum_posts')
        .doc(postId)
        .delete();
  }
}
