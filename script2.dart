import 'dart:io';

void main() {
  final file = File('lib/screens/student/instructional_videos_page.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('\r\n', '\n');
  
  // Replace import (already replaced perhaps? Let's check)
  if (!content.contains('package:youtube_player_flutter')) {
    content = content.replaceAll(
        '''import 'package:webview_flutter/webview_flutter.dart';''',
        '''import 'package:youtube_player_flutter/youtube_player_flutter.dart';''');
  }

  // 1. variables
  final RegExp regExpVars = RegExp(r'  late final WebViewController _webController;\n  bool _isWebViewLoading = true;', multiLine: true, dotAll: true);
  content = content.replaceFirst(
    regExpVars,
    '  YoutubePlayerController? _youtubeController;'
  );

  // 2. initState
  final RegExp regExpInitState = RegExp(r'  @override\n  void initState\(\) \{\n    super.initState\(\);\n    _loadVideos\(\);\n    _initWebController\(\);\n  \}', multiLine: true, dotAll: true);
  content = content.replaceFirst(
    regExpInitState,
    '''  @override
  void initState() {
    super.initState();
    _loadVideos();
  }'''
  );

  // 3. remove _initWebController
  final RegExp regExpInitWeb = RegExp(r'  void _initWebController\(\) \{.*?  \}\n\n  // ? FIXED:', multiLine: true, dotAll: true);
  content = content.replaceFirst(regExpInitWeb, '  // ? FIXED:');
  
  // 4. Update _playVideo
  final RegExp regExpPlay = RegExp(r'  void _playVideo\(ModuleModel module\) \{.*?\}\n', multiLine: true, dotAll: true);
  final String newPlayVideo = '''  void _playVideo(ModuleModel module) {
    final videoUrl = module.videoUrl!;
    final videoId = _extractYouTubeId(videoUrl);

    setState(() {
      _selectedVideoUrl = videoUrl;
      _selectedVideoTitle = module.title;
      _isPlaying = false;
      _hasError = false;
    });

    if (videoId.isNotEmpty) {
      if (_youtubeController == null) {
        _youtubeController = YoutubePlayerController.fromVideoId(
          videoId: videoId,
          autoPlay: true,
          params: const YoutubePlayerParams(
            showFullscreenButton: true,
            mute: false,
          ),
        );
      } else {
        _youtubeController!.loadVideoById(videoId: videoId);
      }
    } else {
      _openInBrowser(videoUrl);
    }
  }\n''';
  content = content.replaceFirst(regExpPlay, newPlayVideo);

  // 5. Update _togglePlayPause
  final RegExp regExpToggle = RegExp(r'  void _togglePlayPause\(\) \{.*?\}\n', multiLine: true, dotAll: true);
  final String newToggle = '''  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_youtubeController != null) {
        if (_isPlaying) {
          _youtubeController!.playVideo();
        } else {
          _youtubeController!.pauseVideo();
        }
      }
    });
  }\n''';
  content = content.replaceFirst(regExpToggle, newToggle);

  // 6. Update _buildVideoPlayer
  final RegExp regExpVideoPlayer = RegExp(r'  Widget _buildVideoPlayer\(\) \{.*?^\s*\}\n', multiLine: true, dotAll: true);
  final String newVideoPlayer = '''  Widget _buildVideoPlayer() {
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
          if (isYouTube && _youtubeController != null) YoutubePlayer(controller: _youtubeController!),
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
        ],
      ),
    );
  }\n''';
  content = content.replaceFirst(regExpVideoPlayer, newVideoPlayer);

  file.writeAsStringSync(content);
}
