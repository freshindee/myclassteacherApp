import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'youtube_webview_player_page.dart';
import '../utils/youtube_utils.dart';

/// Common widget: show thumbnail, on tap open video in YouTube app / browser.
/// In-app WebView was removed to avoid YouTube Error 153 on many devices.
class YoutubeThumbnailPlayer extends StatelessWidget {
  /// Full YouTube URL (watch or youtu.be).
  final String videoUrl;

  /// Thumbnail image URL (e.g. https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg).
  /// If null or empty, a placeholder with play icon is shown.
  final String? thumbUrl;

  /// Optional title for the player app bar.
  final String? title;

  /// Aspect ratio of the thumbnail area. Default 16/9.
  final double aspectRatio;

  /// Border radius for the thumbnail. Default 0 (square). Use e.g. 12 for cards.
  final double borderRadius;

  /// If true, nothing happens on tap when videoUrl is invalid.
  final bool showSnackBarOnInvalidUrl;

  const YoutubeThumbnailPlayer({
    super.key,
    required this.videoUrl,
    this.thumbUrl,
    this.title,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 0,
    this.showSnackBarOnInvalidUrl = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context),
        borderRadius: borderRadius > 0 ? BorderRadius.circular(borderRadius) : null,
        child: ClipRRect(
          borderRadius: borderRadius > 0 ? BorderRadius.circular(borderRadius) : BorderRadius.zero,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _buildThumbnail(context),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final url = thumbUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => _placeholder(context),
            errorWidget: (_, __, ___) => _placeholder(context),
          ),
          Center(
            child: Icon(
              Icons.play_circle_filled,
              size: 72,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    }
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Icon(
          Icons.play_circle_filled,
          size: 72,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (videoUrl.trim().isEmpty) {
      if (showSnackBarOnInvalidUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video URL is not available.')),
        );
      }
      return;
    }
    final videoId = YoutubeUtils.getVideoId(videoUrl);
    if (videoId == null || videoId.isEmpty) {
      if (showSnackBarOnInvalidUrl) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube URL.')),
        );
      }
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => YoutubeWebViewPlayerPage(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }
}
