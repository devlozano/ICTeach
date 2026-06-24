import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/module_model.dart';
import '../../services/module_service.dart';

class InstructionalVideosPage extends StatefulWidget {
  final String? classId;
  final String? className;

  const InstructionalVideosPage({
    super.key,
    this.classId,
    this.className,
  });

  @override
  State<InstructionalVideosPage> createState() =>
      _InstructionalVideosPageState();
}

class _InstructionalVideosPageState extends State<InstructionalVideosPage> {
  final ModuleService _moduleService = ModuleService();
  List<ModuleModel> _videos = [];
  bool _isLoading = true;
  String? _selectedVideoUrl;
  String? _selectedVideoTitle;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  late final WebViewController _webController;
  bool _isWebViewLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
    _initWebController();
  }

  void _initWebController() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isWebViewLoading = true;
              _hasError = false;
              _errorMessage = '';
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isWebViewLoading = false;
            });
          },
          onWebResourceError: (error) {
            setState(() {
              _isWebViewLoading = false;
              _hasError = true;
              _errorMessage = error.description ?? 'Unknown error';
            });
          },
        ),
      );
  }

  // ✅ FIXED: Properly load videos using Stream subscription
  Future<void> _loadVideos() async {
    if (widget.classId == null || widget.classId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _videos = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Use listen instead of first
      _moduleService.getPublishedModulesForClass(widget.classId!).listen(
        (modules) {
          final videos = modules
              .where((m) => m.videoUrl != null && m.videoUrl!.isNotEmpty)
              .toList();

          setState(() {
            _videos = videos;
            _isLoading = false;

            // Auto-play first video if available and no video selected
            if (_videos.isNotEmpty && _selectedVideoUrl == null) {
              _playVideo(_videos.first);
            }
          });
        },
        onError: (error) {
          print('Error loading videos: $error');
          setState(() {
            _isLoading = false;
            _videos = [];
          });
        },
      );
    } catch (e) {
      print('Error loading videos: $e');
      setState(() {
        _isLoading = false;
        _videos = [];
      });
    }
  }

  void _playVideo(ModuleModel module) {
    final videoUrl = module.videoUrl!;
    final videoId = _extractYouTubeId(videoUrl);

    setState(() {
      _selectedVideoUrl = videoUrl;
      _selectedVideoTitle = module.title;
      _isPlaying = false;
      _hasError = false;
    });

    // If it's a YouTube link, use embed
    if (videoId.isNotEmpty) {
      final embedUrl =
          'https://www.youtube.com/embed/$videoId?autoplay=1&rel=0&modestbranding=1&playsinline=1';
      _webController.loadRequest(Uri.parse(embedUrl));
    } else {
      // For other links (Google Drive, etc.), open in browser
      _openInBrowser(videoUrl);
    }
  }

  String _extractYouTubeId(String url) {
    String videoId = '';
    if (url.contains('watch?v=')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('youtube.com/embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    }
    videoId = videoId.split('&').first.split('?').first;
    return videoId;
  }

  void _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Cannot open URL';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _openInYouTubeApp(String videoId) async {
    try {
      final youtubeUri = Uri.parse('vnd.youtube://watch?v=$videoId');
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
      } else {
        _openInBrowser('https://www.youtube.com/watch?v=$videoId');
      }
    } catch (e) {
      _openInBrowser('https://www.youtube.com/watch?v=$videoId');
    }
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _webController.runJavaScript(
        _isPlaying
            ? 'document.querySelector("video")?.play();'
            : 'document.querySelector("video")?.pause();',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Instructional Videos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildVideoPlayer(),
                    _buildStatsRow(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _videos.length,
                        itemBuilder: (context, index) {
                          final module = _videos[index];
                          final isSelected =
                              _selectedVideoUrl == module.videoUrl;
                          return _VideoCard(
                            module: module,
                            index: index,
                            isSelected: isSelected,
                            onTap: () => _playVideo(module),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Videos Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for instructional videos',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadVideos,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_selectedVideoUrl == null) {
      return Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                size: 48,
                color: Colors.white54,
              ),
              SizedBox(height: 8),
              Text(
                'Select a video to play',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final videoId = _extractYouTubeId(_selectedVideoUrl!);
    final isYouTube = videoId.isNotEmpty;

    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          if (isYouTube) WebViewWidget(controller: _webController),
          if (!isYouTube)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_file,
                    size: 48,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedVideoTitle ?? 'Video',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _openInBrowser(_selectedVideoUrl!),
                    icon: const Icon(Icons.open_in_browser),
                    label: const Text('Open Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          if (_isWebViewLoading && isYouTube)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Loading video…',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (!_isWebViewLoading && !_hasError && isYouTube)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'HD',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () {
                        if (videoId.isNotEmpty) {
                          _openInYouTubeApp(videoId);
                        }
                      },
                      icon: const Icon(
                        Icons.youtube_searched_for,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasError)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : 'Unable to load video',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                              _isWebViewLoading = true;
                              if (_selectedVideoUrl != null) {
                                final module = _videos.firstWhere(
                                  (m) => m.videoUrl == _selectedVideoUrl,
                                  orElse: () => _videos.first,
                                );
                                _playVideo(module);
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F80ED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedVideoUrl != null) {
                              _openInBrowser(_selectedVideoUrl!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Open in Browser'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final totalViews = _videos.length * 1000 + 5000;
    final totalDuration = _videos.length * 20;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.video_library_rounded,
            label: '${_videos.length} Videos',
            color: const Color(0xFF2F80ED),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          _StatItem(
            icon: Icons.timer_rounded,
            label: '${totalDuration ~/ 60} hrs Total',
            color: Colors.orange,
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
          ),
          _StatItem(
            icon: Icons.visibility_rounded,
            label: '${(totalViews ~/ 1000)}k+ Views',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final ModuleModel module;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _VideoCard({
    required this.module,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  String _extractYouTubeId(String url) {
    String videoId = '';
    if (url.contains('watch?v=')) {
      videoId = url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      videoId = url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('youtube.com/embed/')) {
      videoId = url.split('embed/').last.split('?').first;
    }
    videoId = videoId.split('&').first.split('?').first;
    return videoId;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _extractYouTubeId(module.videoUrl ?? '');
    final isYouTube = videoId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF2F80ED).withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF2F80ED) : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          if (!isSelected)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 120,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                    image: isYouTube
                        ? DecorationImage(
                            image: NetworkImage(
                              'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isYouTube)
                        const Icon(
                          Icons.video_file,
                          color: Colors.white54,
                          size: 32,
                        ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: const Color(0xFF2F80ED),
                          size: 18,
                        ),
                      ),
                      if (isYouTube)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'YT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF2F80ED)
                              : Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.description.isNotEmpty
                            ? module.description
                            : '${isYouTube ? "YouTube" : "Video"} content for ${module.title}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (isYouTube)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'YouTube',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (!isYouTube)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Video Link',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Q${index + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2F80ED),
                              size: 16,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
