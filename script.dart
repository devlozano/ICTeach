import 'dart:io';

void main() {
  final file = File('lib/screens/student/module_view_page.dart');
  var content = file.readAsStringSync();
  
  final RegExp regExp = RegExp(r'class _YouTubePlayerPageState extends State<YouTubePlayerPage> \{.*?^\}', multiLine: true, dotAll: true);
  
  final String newClass = '''class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // ignore
    }
  }

  void _openInYouTubeApp() async {
    try {
      final youtubeUri = Uri.parse('vnd.youtube://watch?v=\');
      if (await canLaunchUrl(youtubeUri)) {
        await launchUrl(youtubeUri, mode: LaunchMode.externalApplication);
      } else {
        _openInBrowser(widget.originalUrl);
      }
    } catch (e) {
      _openInBrowser(widget.originalUrl);
    }
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
          'YouTube Player',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('? URL copied'),
                      duration: Duration(seconds: 2)),
                );
              }
            },
            icon: const Icon(Icons.copy),
            tooltip: 'Copy URL',
          ),
        ],
      ),
      body: Center(
        child: YoutubePlayer(
          controller: _controller,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.grey.shade900,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.youtube_searched_for, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              const Text('Playing inside the app',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}''';

  content = content.replaceAllMapped(regExp, (match) => newClass);
  file.writeAsStringSync(content);
}
