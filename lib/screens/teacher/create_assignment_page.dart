import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/assignment_model.dart';
import '../../services/assignment_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/notification_service.dart';

class CreateAssignmentPage extends StatefulWidget {
  final String classId;
  final String className;
  final AssignmentModel? assignmentToEdit; // ✅ ADD THIS

  const CreateAssignmentPage({
    super.key,
    required this.classId,
    this.className = '',
    this.assignmentToEdit, // ✅ ADD THIS
  });

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final AssignmentService _assignmentService = AssignmentService();
  final NotificationService _notificationService = NotificationService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxScoreController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublished = false;
  bool _isLoading = false;
  PlatformFile? _selectedFile;
  bool _isEditing = false; // ✅ ADD THIS

  @override
  void initState() {
    super.initState();
    _isEditing = widget.assignmentToEdit != null;

    if (_isEditing) {
      // ✅ Populate fields with existing assignment data
      final assignment = widget.assignmentToEdit!;
      _titleController.text = assignment.title;
      _descriptionController.text = assignment.description;
      _maxScoreController.text = assignment.maxScore.toString();
      _dueDate = assignment.dueDate;
      _isPublished = assignment.isPublished;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectAssignmentFile() async {
    try {
      final file = await CloudinaryService.selectFile();
      if (file == null || !mounted) return;
      setState(() => _selectedFile = file);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      CloudinaryUploadResult? uploadedFile;
      if (_selectedFile != null) {
        uploadedFile = await CloudinaryService.uploadFile(
          file: _selectedFile!,
          folder: CloudinaryService.assignmentsFolder,
        );
      }
      final existingAssignment = widget.assignmentToEdit;

      final assignment = AssignmentModel(
        id: _isEditing ? widget.assignmentToEdit!.id : '',
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        attachmentUrl: uploadedFile?.url ?? existingAssignment?.attachmentUrl,
        attachmentName:
            uploadedFile?.originalFilename ??
            existingAssignment?.attachmentName,
        cloudinaryPublicId:
            uploadedFile?.publicId ?? existingAssignment?.cloudinaryPublicId,
        dueDate: _dueDate,
        maxScore: int.tryParse(_maxScoreController.text) ?? 100,
        isPublished: _isPublished,
        createdAt: _isEditing
            ? widget.assignmentToEdit!.createdAt
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        // ✅ UPDATE existing assignment
        await _assignmentService.updateAssignment(widget.classId, assignment);
        print('✅ Assignment updated: ${assignment.title}');

        // ✅ Send notification if newly published
        if (_isPublished && !widget.assignmentToEdit!.isPublished) {
          print('📢 Sending notification for newly published assignment...');
          try {
            await _notificationService.notifyNewAssignment(
              widget.classId,
              _titleController.text.trim(),
            );
            print('✅ Notification sent to students');
          } catch (e) {
            print('❌ Error sending notification: $e');
          }
        }
      } else {
        // ✅ CREATE new assignment
        await _assignmentService.createAssignment(assignment);
        print('✅ Assignment created: ${assignment.title}');

        // SEND NOTIFICATION TO STUDENTS IF PUBLISHED
        if (_isPublished) {
          print('📢 Attempting to send notifications...');
          try {
            await _notificationService.notifyNewAssignment(
              widget.classId,
              _titleController.text.trim(),
            );
            print('✅ Notification sent to students');
          } catch (e) {
            print('❌ Error sending notification: $e');
          }
        } else {
          print('ℹ️ Assignment saved as draft - no notifications sent');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPublished
                ? '✅ Assignment ${_isEditing ? 'updated' : 'published'}!'
                : '✅ Assignment ${_isEditing ? 'updated' : 'saved'} as draft!',
          ),
          backgroundColor: _isPublished ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error ${_isEditing ? 'updating' : 'creating'} assignment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error ${_isEditing ? 'updating' : 'creating'} assignment: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Assignment' : 'Create Assignment',
        ), // ✅ Dynamic title
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Switch(
            value: _isPublished,
            onChanged: (value) {
              setState(() => _isPublished = value);
            },
            activeThumbColor: Colors.green,
          ),
          const SizedBox(width: 8),
          const Text('Publish', style: TextStyle(color: Colors.white70)),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Name (optional info)
              if (widget.className.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
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
                          '${_isEditing ? 'Editing' : 'Creating'} assignment for: ${widget.className}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Assignment Title',
                  hintText: 'e.g., CSS Module 1 Assignment',
                  prefixIcon: Icon(Icons.assignment),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Assignment title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Detailed description of the assignment',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _selectAssignmentFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _selectedFile?.name ??
                        widget.assignmentToEdit?.attachmentName ??
                        'Attach assignment brief (optional)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              if (_selectedFile != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedFile = null),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Remove selected file'),
                  ),
                ),
              const SizedBox(height: 16),

              // Max Score
              TextFormField(
                controller: _maxScoreController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Score',
                  hintText: '100',
                  prefixIcon: Icon(Icons.score),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Maximum score is required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Due Date
              InkWell(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0B2B4A),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isPublished
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isPublished
                        ? Colors.green.shade200
                        : Colors.amber.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isPublished ? Icons.public : Icons.lock,
                          color: _isPublished ? Colors.green : Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPublished
                              ? 'Published - Students can see this'
                              : 'Draft - Students cannot see this',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _isPublished
                                ? Colors.green.shade800
                                : Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    if (_isPublished) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Students will be notified when ${_isEditing ? 'updated' : 'published'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Toggle the switch to publish and notify students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAssignment,
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
                      : Text(
                          _isEditing
                              ? (_isPublished
                                    ? 'Update & Publish'
                                    : 'Update Draft')
                              : (_isPublished
                                    ? 'Publish Assignment'
                                    : 'Save as Draft'),
                          style: const TextStyle(
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
