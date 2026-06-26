import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Converts Firestore [bank_details] / storage references into a downloadable URL,
/// then displays via [Image.network]. Handles:
/// - `https?://...` (unchanged)
/// - `gs://bucket/path` (via [FirebaseStorage.refFromURL])
/// - Plain storage paths, e.g. `folder/93409a41....jpg` (default bucket)
Future<String> resolveFirebaseImageDownloadUrl(String raw) async {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError('Empty image reference');
  }

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }

  if (lower.startsWith('gs://')) {
    return FirebaseStorage.instance.refFromURL(trimmed).getDownloadURL();
  }

  var path = trimmed;
  while (path.startsWith('/')) {
    path = path.substring(1);
  }
  if (path.isEmpty) {
    throw ArgumentError('Empty storage path');
  }
  return FirebaseStorage.instance.ref(path).getDownloadURL();
}

/// Loads bank detail / Firebase Storage-backed images on web and mobile.
///
/// On **web**, uses [WebHtmlElementStrategy.prefer] so the image loads in an
/// `<img>` (no XHR/CORS byte fetch). Plain [Image.network] defaults to
/// `never`, which fails on many Firebase download URLs (`statusCode: 0`).
///
/// **Do not** use [Reference.getData] on web here: it still goes through HTTP
/// and can throw [ClientException], which FlutterFire may mishandle in JS
/// interop (`ClientException` is not a `JavaScriptObject`).
class ResolvedFirebaseImage extends StatefulWidget {
  const ResolvedFirebaseImage({
    super.key,
    required this.reference,
    this.fit = BoxFit.contain,
    this.width,
  });

  /// Raw value from Firestore (URL, gs://, or storage path).
  final String reference;
  final BoxFit fit;
  final double? width;

  @override
  State<ResolvedFirebaseImage> createState() => _ResolvedFirebaseImageState();
}

class _ResolvedFirebaseImageState extends State<ResolvedFirebaseImage> {
  late Future<String> _urlFuture;

  @override
  void initState() {
    super.initState();
    _urlFuture = resolveFirebaseImageDownloadUrl(widget.reference);
  }

  @override
  void didUpdateWidget(covariant ResolvedFirebaseImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reference != widget.reference) {
      _urlFuture = resolveFirebaseImageDownloadUrl(widget.reference);
    }
  }

  Widget _errorBox(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          const Text(
            'Failed to load image',
            style: TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _urlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return _errorBox(snapshot.error!);
        }

        final url = snapshot.data!;
        final w = widget.width ?? double.infinity;

        return Image.network(
          url,
          fit: widget.fit,
          width: w,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _errorBox(error),
        );
      },
    );
  }
}
