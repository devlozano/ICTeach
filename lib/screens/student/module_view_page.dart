import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/module_model.dart';
import '../../services/module_service.dart';

class ModuleViewPage extends StatefulWidget {
  final String classId;
  final String className;

  const ModuleViewPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ModuleViewPage> createState() => _ModuleViewPageState();
}

class _ModuleViewPageState extends State<ModuleViewPage> {
  final ModuleService _moduleService = ModuleService();
  int? _selectedModuleIndex;

  String extractYouTubeId(String url) {
    String videoId = '';
    if (url.contains('watch?v=')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('youtube.com/embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    } else if (url.contains('m.youtube.com/watch')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtube.com/shorts/')) {
      videoId = url.split('shorts/').last.split('?').first;
    }
    videoId = videoId.split('&').first.split('?').first;
    return videoId;
  }

  void _openVideo(String url) async {
    try {
      final videoId = extractYouTubeId(url);
      String finalUrl = url;

      if (videoId.isNotEmpty) {
        // Try to open in YouTube app first
        final youtubeUri = Uri.parse('vnd.youtube://watch?v=$videoId');
        if (await canLaunchUrl(youtubeUri)) {
          await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
          return;
        }
        // Fallback to browser
        finalUrl = 'https://www.youtube.com/watch?v=$videoId';
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCannotOpenDialog(url);
      }
    } catch (e) {
      _showCannotOpenDialog(url);
    }
  }

  void _openFile(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCannotOpenDialog(url);
      }
    } catch (e) {
      _showCannotOpenDialog(url);
    }
  }

  void _showCannotOpenDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Open'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We could not open this file automatically.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ URL copied'),
                    duration: Duration(seconds: 2)),
              );
              Navigator.pop(context);
            },
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showVideoOptions(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch Video'),
        content: const Text('Choose how to watch:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openVideo(url);
            },
            child: const Text('▶ Watch'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ URL copied'),
                    duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Copy URL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: const Color(0xFF428DEB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ModuleModel>>(
        stream: _moduleService.getPublishedModulesForClass(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final modules = snapshot.data ?? [];
          if (modules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No modules available yet',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Check back later',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          if (_selectedModuleIndex == null) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: modules.length,
              itemBuilder: (context, index) {
                final module = modules[index];
                return _ModuleListItem(
                  module: module,
                  index: index,
                  onTap: () => setState(() => _selectedModuleIndex = index),
                );
              },
            );
          } else {
            final module = modules[_selectedModuleIndex!];
            return _ModuleContent(
              module: module,
              onBack: () => setState(() => _selectedModuleIndex = null),
              totalModules: modules.length,
              currentIndex: _selectedModuleIndex!,
              onNext: () {
                if (_selectedModuleIndex! < modules.length - 1) {
                  setState(
                      () => _selectedModuleIndex = _selectedModuleIndex! + 1);
                }
              },
              onPrevious: () {
                if (_selectedModuleIndex! > 0) {
                  setState(
                      () => _selectedModuleIndex = _selectedModuleIndex! - 1);
                }
              },
              hasNext: _selectedModuleIndex! < modules.length - 1,
              hasPrevious: _selectedModuleIndex! > 0,
              openVideo: _openVideo,
              openFile: _openFile,
              showVideoOptions: _showVideoOptions,
            );
          }
        },
      ),
    );
  }
}

// Module List Item
class _ModuleListItem extends StatelessWidget {
  final ModuleModel module;
  final int index;
  final VoidCallback onTap;

  const _ModuleListItem({
    required this.module,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF428DEB).withValues(alpha: 0.1),
          child: Text('${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF428DEB))),
        ),
        title: Text(module.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: module.description.isNotEmpty
            ? Text(module.description,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing:
            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF428DEB)),
        onTap: onTap,
      ),
    );
  }
}

// Module Content View
class _ModuleContent extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onBack;
  final int totalModules;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool hasNext;
  final bool hasPrevious;
  final void Function(String) openVideo;
  final void Function(String) openFile;
  final void Function(String) showVideoOptions;

  const _ModuleContent({
    required this.module,
    required this.onBack,
    required this.totalModules,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.hasNext,
    required this.hasPrevious,
    required this.openVideo,
    required this.openFile,
    required this.showVideoOptions,
  });

  @override
  Widget build(BuildContext context) {
    final hasVideo = module.videoUrl != null && module.videoUrl!.isNotEmpty;
    final hasFile =
        module.attachmentUrl != null && module.attachmentUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Progress
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Module ${currentIndex + 1} of $totalModules',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(module.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress indicator
          Row(
            children: List.generate(totalModules, (index) {
              final isActive = index == currentIndex;
              final isCompleted = index < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF428DEB)
                        : isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Description
          if (module.description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(module.description,
                        style: TextStyle(color: Colors.blue.shade900)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Video Section
          if (hasVideo) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.video_library_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Instructional Video',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Video Preview
                  GestureDetector(
                    onTap: () => openVideo(module.videoUrl!),
                    child: Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_filled_rounded,
                                color: Colors.white, size: 64),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to Watch',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => openVideo(module.videoUrl!),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('▶ Watch Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => showVideoOptions(module.videoUrl!),
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        tooltip: 'More options',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Opens in YouTube app or browser',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // File Attachment
          if (hasFile) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_file, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Attachment',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => openFile(module.attachmentUrl!),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'View / Download File',
                            style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Icon(Icons.open_in_new,
                            color: Colors.blue, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lesson Content',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Text(module.content,
                    style: const TextStyle(height: 1.6, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Competencies
          if (module.competencies.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Competencies Covered',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...module.competencies.map((comp) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(comp,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Navigation Buttons
          Row(
            children: [
              if (hasPrevious)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF428DEB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (hasPrevious && hasNext) const SizedBox(width: 12),
              if (hasNext)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF428DEB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              if (!hasNext)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
