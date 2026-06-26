import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late YoutubePlayerController? _controller;
  String? _errorMessage;

  static String? getYouTubeVideoId(String url) {
    try {
      String cleanUrl = url.trim();
      if (cleanUrl.startsWith('@')) {
        cleanUrl = cleanUrl.substring(1);
      }
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) return null;
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      }
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final videoId = getYouTubeVideoId(widget.videoUrl);
    if (videoId != null && videoId.isNotEmpty) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          mute: false,
          loop: false,
        ),
      );
    } else {
      _controller = null;
      _errorMessage = 'Invalid YouTube URL format';
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Video Player'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Could not load video',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller!,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Video Player'),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: player,
              ),
            ],
          ),
        );
      },
    );
  }
}
