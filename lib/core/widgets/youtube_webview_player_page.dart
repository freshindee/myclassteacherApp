import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/youtube_utils.dart';

/// Opens the video in the YouTube app or browser.
///
/// YouTube Error 153 ("video player configuration error") occurs when embedding
/// the player inside an in-app WebView on many devices. Opening the watch URL
/// externally avoids that entirely and is the reliable playback path.
class YoutubeWebViewPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? title;

  const YoutubeWebViewPlayerPage({
    super.key,
    required this.videoUrl,
    this.title,
  });

  @override
  State<YoutubeWebViewPlayerPage> createState() => _YoutubeWebViewPlayerPageState();
}

class _YoutubeWebViewPlayerPageState extends State<YoutubeWebViewPlayerPage> {
  bool _launchFailed = false;
  bool _launched = false;

  String? get _watchUrl {
    final u = widget.videoUrl.trim();
    if (u.isEmpty) return null;
    final videoId = YoutubeUtils.getVideoId(u);
    if (videoId == null) return u;
    final start = YoutubeUtils.getStartTimeSeconds(u);
    final startParam = start != null && start > 0 ? '&t=${start}' : '';
    return 'https://www.youtube.com/watch?v=$videoId$startParam';
  }

  String? get _thumbUrl {
    final id = YoutubeUtils.getVideoId(widget.videoUrl);
    if (id == null || id.isEmpty) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInYouTube(attemptPop: true));
  }

  Future<void> _openInYouTube({bool attemptPop = false}) async {
    final url = _watchUrl;
    if (url == null || url.isEmpty) {
      if (mounted) setState(() => _launchFailed = true);
      return;
    }
    final uri = Uri.parse(url);
    try {
      final ok = await canLaunchUrl(uri);
      if (!ok) {
        if (mounted) setState(() => _launchFailed = true);
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _launched = true;
      if (attemptPop && mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) setState(() => _launchFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalidUrl = _watchUrl == null;
    if (invalidUrl) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Video'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Invalid YouTube URL'),
        ),
      );
    }

    // Brief loading while launching; if launch fails, show fallback UI.
    if (!_launchFailed && !_launched) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Video'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening YouTube…'),
            ],
          ),
        ),
      );
    }

    if (_launchFailed) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'Video'),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (_thumbUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        _thumbUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                if (widget.title != null && widget.title!.isNotEmpty)
                  Text(
                    widget.title!,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 16),
                const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'In-app playback is not available on this device.\n'
                  'Tap below to watch in the YouTube app or browser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => _openInYouTube(attemptPop: false),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch on YouTube'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Launched and popped — should not build; return empty if still mounted briefly.
    return const Scaffold(body: SizedBox.shrink());
  }
}
