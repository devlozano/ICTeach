import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/forum_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/forum_service.dart';

class CreateForumPostPage extends StatefulWidget {
  final String classId;
  final String className;

  const CreateForumPostPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateForumPostPage> createState() => _CreateForumPostPageState();
}

class _CreateForumPostPageState extends State<CreateForumPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  final ForumService _forumService = ForumService();
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_isLoading) return;
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (!mounted) return;
      if (images.length + _selectedImages.length > 5) {
        _showSnackBar('You can attach up to 5 images per post.', Colors.orange);
        return;
      }
      for (final file in images) {
        final extension = file.name.split('.').last.toLowerCase();
        if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension) ||
            await file.length() > 10 * 1024 * 1024) {
          if (mounted) {
            _showSnackBar(
              'Choose JPG, PNG or WebP images up to 10 MB each.',
              Colors.orange,
            );
          }
          return;
        }
      }
      if (mounted) setState(() => _selectedImages.addAll(images));
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          'Could not open your images. Check photo permissions and try again.',
          Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<List<String>> _uploadSelectedImages() async {
    if (_selectedImages.isEmpty) return const [];

    final List<String> urls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final bytes = await file.readAsBytes();
      final uploadedFile = await CloudinaryService.uploadBytes(
        bytes: bytes,
        filename: file.name,
        folder: CloudinaryService.forumPostsFolder,
      );
      urls.add(uploadedFile.url);
    }

    return urls;
  }

  Future<void> _createPost() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please login first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};
      final authorName =
          userData['displayName']?.toString() ??
          userData['name']?.toString() ??
          user.displayName ??
          'Student';
      final authorRole = userData['role']?.toString() ?? 'student';
      final imageUrls = await _uploadSelectedImages();

      final post = ForumPost(
        id: '',
        classId: widget.classId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        authorName: authorName,
        authorRole: authorRole,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likeCount: 0,
        likedBy: [],
        viewCount: 0,
        replyCount: 0,
      );

      await _forumService.createPost(post);

      if (!mounted) return;

      _showSnackBar(
        '✅ Post created! Notifications sent to all students, teachers, and trainers (except you).',
        Colors.green,
      );
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('❌ Error creating post: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.class_, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Posting in: ${widget.className}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Post Title',
                  hintText: 'What do you want to discuss?',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  counterText: '',
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                minLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Describe your question or topic...',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter content';
                  }
                  if (value.length < 10) {
                    return 'Content must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image Picker Row
              Row(
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : _pickImages,
                    icon: const Icon(Icons.image, color: Color(0xFF0B2B4A)),
                    tooltip: 'Add Image',
                  ),
                  if (_selectedImages.isNotEmpty)
                    Expanded(
                      child: SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 80,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FutureBuilder(
                                    future: _selectedImages[index]
                                        .readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                      icon: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All students in this class will be notified when you post.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B2B4A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Post',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
