import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool _isLoading = true;
  String? _errorMessage;

  String? _getYouTubeVideoId(String url) {
    try {
      // Handle URLs with @ symbol at the beginning
      String cleanUrl = url.trim();
      if (cleanUrl.startsWith('@')) {
        cleanUrl = cleanUrl.substring(1);
      }
      
      final uri = Uri.tryParse(cleanUrl);
      if (uri == null) return null;
      
      developer.log('🎬 VideoPlayerPage: Parsing URL: $cleanUrl', name: 'VideoPlayerPage');
      developer.log('🎬 VideoPlayerPage: URI host: ${uri.host}', name: 'VideoPlayerPage');
      developer.log('🎬 VideoPlayerPage: URI path: ${uri.path}', name: 'VideoPlayerPage');
      developer.log('🎬 VideoPlayerPage: URI query parameters: ${uri.queryParameters}', name: 'VideoPlayerPage');
      
      if (uri.host.contains('youtu.be')) {
        final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        developer.log('🎬 VideoPlayerPage: YouTube short URL, video ID: $videoId', name: 'VideoPlayerPage');
        return videoId;
      } else if (uri.host.contains('youtube.com')) {
        final videoId = uri.queryParameters['v'];
        developer.log('🎬 VideoPlayerPage: YouTube full URL, video ID: $videoId', name: 'VideoPlayerPage');
        return videoId;
      }
      return null;
    } catch (e) {
      developer.log('❌ VideoPlayerPage: Error parsing URL: $e', name: 'VideoPlayerPage');
      return null;
    }
  }

  Future<void> _playYouTubeVideo(BuildContext context) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      developer.log('🎬 VideoPlayerPage: Starting video playback for URL: ${widget.videoUrl}', name: 'VideoPlayerPage');
      
      final videoId = _getYouTubeVideoId(widget.videoUrl);
      
      if (videoId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid YouTube URL format';
        });
        developer.log('❌ VideoPlayerPage: Could not extract video ID from URL', name: 'VideoPlayerPage');
        return;
      }

      developer.log('🎬 VideoPlayerPage: Extracted video ID: $videoId', name: 'VideoPlayerPage');

      // Try to open in YouTube app first
      final appUrl = Uri.parse('youtube://$videoId');
      developer.log('🎬 VideoPlayerPage: Trying YouTube app URL: $appUrl', name: 'VideoPlayerPage');
      
      if (await canLaunchUrl(appUrl)) {
        developer.log('🎬 VideoPlayerPage: YouTube app available, launching...', name: 'VideoPlayerPage');
        await launchUrl(appUrl, mode: LaunchMode.externalApplication);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fallback to web URL
      final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');
      developer.log('🎬 VideoPlayerPage: YouTube app not available, trying web URL: $webUrl', name: 'VideoPlayerPage');
      
      if (await canLaunchUrl(webUrl)) {
        developer.log('🎬 VideoPlayerPage: Launching in browser...', name: 'VideoPlayerPage');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not open YouTube app or browser';
        });
        developer.log('❌ VideoPlayerPage: Could not launch any YouTube URL', name: 'VideoPlayerPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error playing video: $e';
      });
      developer.log('❌ VideoPlayerPage: Error during video playback: $e', name: 'VideoPlayerPage');
    }
  }

  @override
  void initState() {
    super.initState();
    // Delay to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playYouTubeVideo(context);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Opening YouTube video...'),
            ] else if (_errorMessage != null) ...[
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _playYouTubeVideo(context),
                child: const Text('Try Again'),
              ),
            ] else ...[
              const Icon(
                Icons.play_circle_outline,
                size: 64,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              const Text('Video opened successfully!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _playYouTubeVideo(context),
                child: const Text('Open Again'),
              ),
            ],
            const SizedBox(height: 20),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Video Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('URL: ${widget.videoUrl}'),
                    if (_getYouTubeVideoId(widget.videoUrl) != null)
                      Text('Video ID: ${_getYouTubeVideoId(widget.videoUrl)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 