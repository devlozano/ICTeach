import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/module_model.dart';
import '../../services/module_service.dart';

// ---------------------------------------------------------------------
//  MAIN PAGE – ModuleViewPage
// ---------------------------------------------------------------------
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

  // -----------------------------------------------------------------
  //  Helper: Extract YouTube Video ID (handles all URL formats)
  // -----------------------------------------------------------------
  String extractYouTubeId(String url) {
    String videoId = '';

    // Try different URL patterns
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

    // Clean up any extra parameters
    videoId = videoId.split('&').first.split('?').first;

    // If still empty, try to extract with regex
    if (videoId.isEmpty) {
      final RegExp regExp = RegExp(
        r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/shorts\/)([^&\n?#]+)',
        caseSensitive: false,
      );
      final match = regExp.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        videoId = match.group(1) ?? '';
      }
    }

    return videoId;
  }

  // -----------------------------------------------------------------
  //  Play in-app with WebView
  // -----------------------------------------------------------------
  void _playInApp(String url) {
    final videoId = extractYouTubeId(url);
    if (videoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not extract video ID. Please try opening in browser.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      _showVideoOptions(url);
      return;
    }

    // Use a clean embed URL without extra parameters that might cause errors
    final embedUrl =
        'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YouTubePlayerPage(
          embedUrl: embedUrl,
          videoId: videoId,
          originalUrl: url,
        ),
      ),
    );
  }

  // -----------------------------------------------------------------
  //  Open in YouTube App
  // -----------------------------------------------------------------
  void _openInYouTubeApp(String url) async {
    try {
      final videoId = extractYouTubeId(url);
      if (videoId.isEmpty) {
        _openInBrowser(url);
        return;
      }
      final youtubeUri = Uri.parse('vnd.youtube://watch?v=$videoId');
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
        return;
      }
      _openInBrowser(url);
    } catch (e) {
      _openInBrowser(url);
    }
  }

  // -----------------------------------------------------------------
  //  Open in Browser
  // -----------------------------------------------------------------
  void _openInBrowser(String url) async {
    try {
      final videoId = extractYouTubeId(url);
      final String finalUrl;
      if (videoId.isNotEmpty) {
        finalUrl = 'https://www.youtube.com/watch?v=$videoId';
      } else {
        finalUrl = url;
      }

      final uri = Uri.parse(finalUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCannotLaunchDialog(finalUrl);
      }
    } catch (e) {
      _showCannotLaunchDialog(url);
    }
  }

  // -----------------------------------------------------------------
  //  Fallback Dialog – when nothing works
  // -----------------------------------------------------------------
  void _showCannotLaunchDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Open Video'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We could not open the video automatically.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Copy the URL and paste it into your browser:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
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
                    content: Text('✅ URL copied!'),
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

  // -----------------------------------------------------------------
  //  Show Options Dialog (Play In-App / YouTube App / Browser / Copy)
  // -----------------------------------------------------------------
  void _showVideoOptions(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Watch Video'),
        content: const Text('Choose how to watch this video:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playInApp(url);
            },
            child: const Text('Play In-App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInYouTubeApp(url);
            },
            child: const Text('YouTube App'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openInBrowser(url);
            },
            child: const Text('Browser'),
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

  // -----------------------------------------------------------------
  //  Build
  // -----------------------------------------------------------------
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
                  Text('Check back later for learning materials',
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
              showVideoOptions: _showVideoOptions,
              playInApp: _playInApp,
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  YOUTUBE PLAYER PAGE – In‑App WebView (FIXED)
// ---------------------------------------------------------------------
class YouTubePlayerPage extends StatefulWidget {
  final String embedUrl;
  final String videoId;
  final String originalUrl;

  const YouTubePlayerPage({
    super.key,
    required this.embedUrl,
    required this.videoId,
    required this.originalUrl,
  });

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // ✅ Configure WebView with proper settings
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
              _errorMessage = '';
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description ?? 'Unknown error';
            });
          },
          onNavigationRequest: (request) {
            // Allow YouTube and its related domains
            if (request.url.contains('youtube.com') ||
                request.url.contains('youtu.be') ||
                request.url.contains('googlevideo.com') ||
                request.url.contains('ytimg.com') ||
                request.url.contains('google.com')) {
              return NavigationDecision.navigate;
            }
            // Block any external links from opening inside WebView
            if (request.url.startsWith('http')) {
              // Open in browser instead
              _openInBrowser(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.embedUrl));
  }

  void _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error opening browser: $e');
    }
  }

  void _openInYouTubeApp() async {
    try {
      final youtubeUri = Uri.parse('vnd.youtube://watch?v=${widget.videoId}');
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
      } else {
        _openInBrowser(widget.originalUrl);
      }
    } catch (e) {
      _openInBrowser(widget.originalUrl);
    }
  }

  void _reloadVideo() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _controller.loadRequest(Uri.parse(widget.embedUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🎬 Video Player',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _openInYouTubeApp,
            icon: const Icon(Icons.youtube_searched_for, color: Colors.red),
            tooltip: 'Open in YouTube App',
          ),
          IconButton(
            onPressed: () => _openInBrowser(widget.originalUrl),
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in Browser',
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.originalUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('✅ URL copied'),
                    duration: Duration(seconds: 2)),
              );
            },
            icon: const Icon(Icons.copy),
            tooltip: 'Copy URL',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🔥 WebView
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading video…',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Error overlay
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Cannot Play Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : 'Try opening in YouTube app or browser.',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _reloadVideo,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _openInYouTubeApp,
                          icon:
                              const Icon(Icons.youtube_searched_for, size: 18),
                          label: const Text('YouTube App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _openInBrowser(widget.originalUrl),
                          icon: const Icon(Icons.open_in_browser, size: 18),
                          label: const Text('Browser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.originalUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✅ URL copied'),
                              duration: Duration(seconds: 2)),
                        );
                      },
                      child: const Text(
                        'Copy URL',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_hasError
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.grey.shade900,
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.youtube_searched_for,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      '▶ Playing inside the app',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------
//  MODULE LIST ITEM
// ---------------------------------------------------------------------
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
          backgroundColor: const Color(0xFF428DEB).withOpacity(0.1),
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

// ---------------------------------------------------------------------
//  MODULE CONTENT VIEW
// ---------------------------------------------------------------------
class _ModuleContent extends StatelessWidget {
  final ModuleModel module;
  final VoidCallback onBack;
  final int totalModules;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final bool hasNext;
  final bool hasPrevious;
  final void Function(String) showVideoOptions;
  final void Function(String) playInApp;

  const _ModuleContent({
    required this.module,
    required this.onBack,
    required this.totalModules,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
    required this.hasNext,
    required this.hasPrevious,
    required this.showVideoOptions,
    required this.playInApp,
  });

  void _openFileLink(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cannot open file link'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = module.videoUrl != null && module.videoUrl!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Back + Progress ----
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

          // ---- Progress indicator ----
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

          // ---- Description ----
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

          // ---- VIDEO SECTION ----
          if (hasVideo) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
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

                  // Video Thumbnail / Preview
                  GestureDetector(
                    onTap: () => playInApp(module.videoUrl!),
                    child: Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
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
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.youtube_searched_for,
                                      color: Colors.red, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    '▶ In-App',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Action Buttons ----
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => playInApp(module.videoUrl!),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('▶ Play In‑App'),
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
                          'Plays inside the app • Tap ⋮ for YouTube app/browser',
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

          // ---- FILE ATTACHMENT ----
          if (module.attachmentUrl != null &&
              module.attachmentUrl!.isNotEmpty) ...[
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
                    onTap: () {
                      _openFileLink(module.attachmentUrl!, context);
                    },
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

          // ---- CONTENT ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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

          // ---- COMPETENCIES ----
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

          // ---- NAVIGATION BUTTONS ----
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
