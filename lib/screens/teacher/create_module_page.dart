import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../models/module_model.dart';
import '../../services/module_service.dart';

class CreateModulePage extends StatefulWidget {
  final String classId;

  const CreateModulePage({super.key, required this.classId});

  @override
  State<CreateModulePage> createState() => _CreateModulePageState();
}

class _CreateModulePageState extends State<CreateModulePage> {
  final _formKey = GlobalKey<FormState>();
  final ModuleService _moduleService = ModuleService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _youtubeLinkController = TextEditingController();
  final _fileLinkController = TextEditingController();

  bool _isLoading = false;
  bool _isPublished = false;
  int _order = 0;
  List<String> _competencies = [];
  bool _videoLinkValid = false;
  bool _fileLinkValid = false;

  final List<String> _competencyOptions = [
    'CSS-01: Install computer systems and networks',
    'CSS-02: Diagnose and troubleshoot computer systems',
    'CSS-03: Configure computer systems and networks',
    'CSS-04: Maintain computer systems and networks',
    'CSS-05: Setup computer networks',
    'CSS-06: Configure and maintain computer systems',
    'CSS-07: Identify computer parts and peripherals',
    'CSS-08: Assemble computer system units',
    'CSS-09: Troubleshoot computer hardware',
    'CSS-10: Use proper tools and equipment',
  ];

  @override
  void initState() {
    super.initState();
    _loadModuleCount();
    _youtubeLinkController.addListener(_validateYoutubeLink);
    _fileLinkController.addListener(_validateFileLink);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _youtubeLinkController.dispose();
    _fileLinkController.dispose();
    super.dispose();
  }

  void _validateYoutubeLink() {
    final url = _youtubeLinkController.text.trim();
    final isValid =
        url.isNotEmpty &&
        (url.contains('youtube.com/watch') ||
            url.contains('youtu.be/') ||
            url.contains('youtube.com/embed') ||
            url.contains('m.youtube.com'));
    setState(() {
      _videoLinkValid = isValid;
    });
  }

  void _validateFileLink() {
    final url = _fileLinkController.text.trim();
    final isValid =
        url.isNotEmpty &&
        (url.contains('drive.google.com') ||
            url.contains('docs.google.com') ||
            url.startsWith('https://'));
    setState(() {
      _fileLinkValid = isValid && _isValidUrl(url);
    });
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadModuleCount() async {
    try {
      final count = await _moduleService.getModuleCount(widget.classId);
      setState(() {
        _order = count;
      });
    } catch (e) {
      print('Error loading module count: $e');
    }
  }

  String extractYouTubeId(String url) {
    String videoId = '';
    if (url.contains('watch?v=')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    } else if (url.contains('m.youtube.com/watch')) {
      videoId = url.split('watch?v=').last.split('&').first;
    }
    return videoId;
  }

  // ✅ FIXED: Open file link with proper error handling (StatefulWidget so mounted exists)
  Future<void> _openFileLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Copy link to clipboard
  void _copyLink(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final videoUrl = _youtubeLinkController.text.trim().isEmpty
          ? null
          : _youtubeLinkController.text.trim();

      if (videoUrl != null) {
        final videoId = extractYouTubeId(videoUrl);
        if (videoId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Please enter a valid YouTube URL'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final attachmentUrl = _fileLinkController.text.trim().isEmpty
          ? null
          : _fileLinkController.text.trim();

      final module = ModuleModel(
        id: '',
        classId: widget.classId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        content: _contentController.text.trim(),
        videoUrl: videoUrl,
        order: _order,
        competencies: _competencies,
        attachmentUrl: attachmentUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPublished: _isPublished,
      );

      await _moduleService.createModule(module);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Module created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error creating module: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: const Text('Create Module'),
        backgroundColor: const Color(0xFF0B2B4A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Switch(
            value: _isPublished,
            onChanged: (value) {
              setState(() => _isPublished = value);
            },
            activeColor: Colors.green,
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
              // Module Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Module Title',
                  hintText: 'e.g., Introduction to Computer Systems',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Module title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the module',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Lesson Content',
                  hintText: 'Write the lesson content here...',
                  prefixIcon: Icon(Icons.article),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lesson content is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Video Section - YouTube
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.video_library, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text(
                          'YouTube Video (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_videoLinkValid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Valid Link',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Paste any YouTube video link. The video will play inside the app!',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _youtubeLinkController,
                      decoration: InputDecoration(
                        labelText: 'YouTube Video URL',
                        hintText: 'https://www.youtube.com/watch?v=...',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: _youtubeLinkController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _youtubeLinkController.clear();
                                  setState(() {
                                    _videoLinkValid = false;
                                  });
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final videoId = extractYouTubeId(value);
                          if (videoId.isEmpty) {
                            return 'Please enter a valid YouTube URL';
                          }
                        }
                        return null;
                      },
                    ),
                    if (_youtubeLinkController.text.isNotEmpty &&
                        _videoLinkValid) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'YouTube video will play inside the app!',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // File Attachment Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file, color: Color(0xFF0B2B4A)),
                        const SizedBox(width: 8),
                        const Text(
                          'File Attachment (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_fileLinkValid)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Valid Link',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Paste a Google Drive, OneDrive, or any cloud storage shareable link.\n'
                              'Tip: Upload your file to Google Drive → Share → Copy link',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fileLinkController,
                      decoration: InputDecoration(
                        labelText: 'File Link (Google Drive, OneDrive, etc.)',
                        hintText: 'https://drive.google.com/file/d/...',
                        prefixIcon: const Icon(Icons.cloud),
                        suffixIcon: _fileLinkController.text.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_fileLinkValid) {
                                        _openFileLink(_fileLinkController.text);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.open_in_browser,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Test Link',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _copyLink(_fileLinkController.text);
                                    },
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    tooltip: 'Copy Link',
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _fileLinkController.clear();
                                      setState(() {
                                        _fileLinkValid = false;
                                      });
                                    },
                                    icon: const Icon(Icons.clear, size: 18),
                                  ),
                                ],
                              )
                            : null,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!_isValidUrl(value)) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                    if (_fileLinkController.text.isNotEmpty &&
                        _fileLinkValid) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'File link is valid! Students can view/download from the link.',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Competencies
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Competencies',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select relevant competencies for this module',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _competencyOptions.map((competency) {
                        final isSelected = _competencies.contains(competency);
                        return FilterChip(
                          label: Text(
                            competency,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _competencies.add(competency);
                              } else {
                                _competencies.remove(competency);
                              }
                            });
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: const Color(0xFF0B2B4A),
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF0B2B4A)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order and Status
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _order.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Module Order',
                        hintText: '0',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _order = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
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
                      child: Row(
                        children: [
                          Icon(
                            _isPublished ? Icons.public : Icons.lock,
                            color: _isPublished ? Colors.green : Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPublished ? 'Published' : 'Draft',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isPublished ? Colors.green : Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveModule,
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
                          'Create Module',
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
