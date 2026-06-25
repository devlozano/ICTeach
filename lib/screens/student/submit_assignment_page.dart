import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';

class SubmitAssignmentPage extends StatefulWidget {
  final String classId;
  final AssignmentModel assignment;

  const SubmitAssignmentPage({
    super.key,
    required this.classId,
    required this.assignment,
  });

  @override
  State<SubmitAssignmentPage> createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  final AssignmentService _assignmentService = AssignmentService();
  final TextEditingController _contentController = TextEditingController();

  File? _selectedFile;
  String? _uploadedFileUrl;
  String? _selectedFileName;
  bool _isUploading = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'zip'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
          _uploadedFileUrl = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          '_' +
          _selectedFileName!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('submissions')
          .child(widget.classId)
          .child(fileName);

      final uploadTask = storageRef.putFile(_selectedFile!);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedFileUrl = downloadUrl;
        _isUploading = false;
        _selectedFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ File uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error uploading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitAssignment() async {
    // Check if content is provided
    final content = _contentController.text.trim();
    if (content.isEmpty && _uploadedFileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide content or upload a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check minimum character requirement
    if (content.isNotEmpty && content.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please provide a more detailed answer (at least 10 characters)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      final submission = AssignmentSubmission(
        id: '',
        assignmentId: widget.assignment.id,
        studentId: user.uid,
        studentName: user.displayName ?? 'Student',
        content: content,
        attachmentUrl: _uploadedFileUrl,
        score: 0,
        submittedAt: DateTime.now(),
        isGraded: false,
      );

      await _assignmentService.submitAssignment(submission);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Assignment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error submitting assignment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _getCharacterCountText() {
    final length = _contentController.text.length;
    return length == 0
        ? '0 characters (minimum 10)'
        : '$length characters (minimum 10)';
  }

  Color _getCharacterCountColor() {
    final length = _contentController.text.length;
    if (length == 0) return Colors.grey[400]!;
    if (length < 10) return Colors.orange;
    return Colors.green[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Submit Assignment'),
        backgroundColor: const Color(0xFF428DEB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.assignment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Due: ${widget.assignment.dueDate.day}/${widget.assignment.dueDate.month}/${widget.assignment.dueDate.year}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.assignment.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Max Score: ${widget.assignment.maxScore}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF428DEB),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instructions Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'The answer box expands as you type. Minimum 10 characters required.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Label
            const Text(
              'Your Answer:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Auto-Expanding TextField with Max Height
            Container(
              constraints: BoxConstraints(
                minHeight: 150,
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: TextFormField(
                controller: _contentController,
                maxLines: null, // This allows unlimited expansion
                minLines: 5, // Start with 5 lines visible
                maxLength: 1000, // Optional: limit total characters
                decoration: InputDecoration(
                  labelText: 'Your Answer',
                  hintText: 'Write your answer here...',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.grey[50],
                  counterText:
                      '', // Hide character counter if you don't want it
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please write your answer';
                  }
                  if (value.length < 10) {
                    return 'Your answer should be at least 10 characters';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Optional: auto-save draft or update character count
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 20),

            // File Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attachment (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFile == null && _uploadedFileUrl == null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickFile,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Choose File'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_selectedFile != null && _uploadedFileUrl == null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'Selected file',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _selectedFileName = null;
                              });
                            },
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _uploadFile,
                            icon: _isUploading
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.upload_file),
                            label: _isUploading
                                ? Text(
                                    'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%')
                                : const Text('Upload File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF428DEB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _selectedFileName = null;
                            });
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                  if (_uploadedFileUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName ?? 'File uploaded',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _uploadedFileUrl = null;
                                _selectedFileName = null;
                              });
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Remove file',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_isUploading) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                      color: const Color(0xFF428DEB),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Submit Assignment',
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
    );
  }
}
