// ✅ COMMENTED OUT - Not being used currently
// import 'package:youtube_explode_dart/youtube_explode_dart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io';

class YouTubeService {
  // ✅ Comment out the implementation
  // final yt = YoutubeExplode();

  // Extract video ID from URL
  String extractVideoId(String url) {
    if (url.contains('watch?v=')) {
      return url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('youtube.com/embed/')) {
      return url.split('embed/').last.split('?').first;
    }
    return '';
  }

  // Get video info and stream URL
  Future<String?> getVideoStreamUrl(String url) async {
    // ✅ Return null since we're not using this
    return null;
  }

  // Get video details
  Future<Map<String, dynamic>?> getVideoDetails(String url) async {
    // ✅ Return null since we're not using this
    return null;
  }

  void dispose() {
    // ✅ Empty dispose
  }
}
