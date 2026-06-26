import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';
import '../database/school_cache_database.dart';
import '../network/api_client.dart';

/// Fetches school content (video, pdf_notes, zoom_classes) from get_school_content.php.
/// Uses same base URL and ApiClient as exam papers API. Throttled to at most once per 30 seconds
/// per school_id. Runs in background; response is not cancelled if the user navigates away.
class SchoolContentService {
  final ApiClient apiClient;

  SchoolContentService({required this.apiClient});

  static const Duration _throttleDuration = Duration(seconds: 30);
  static const String _prefsKeyPrefix = 'school_content_last_fetch_';

  /// Triggers fetch if the last call for this [schoolId] was more than 30 seconds ago.
  /// Does not await: runs in background. Logs video, pdf_notes, zoom_classes to console on success.
  void fetchSchoolContentIfNeeded(String schoolId) {
    if (schoolId.isEmpty) return;
    _runInBackground(schoolId);
  }

  void _runInBackground(String schoolId) async {
    try {
      if (schoolId.isEmpty) {
        print('📦 [SchoolContent] Skipping fetch: school_id is empty');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsKeyPrefix$schoolId';
      final lastMs = prefs.getInt(key);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (lastMs != null) {
        final elapsed = Duration(milliseconds: now - lastMs);
        if (elapsed < _throttleDuration) {
          print('📦 [SchoolContent] Skipping fetch: last call was ${elapsed.inSeconds} seconds ago (throttle: 30 seconds)');
          return;
        }
      }

      // PHP API expects GET: $_GET['school_id']. Append query to endpoint so the URL is guaranteed correct.
      final endpointWithQuery =
          '${ApiEndpoints.getSchoolContent}?school_id=${Uri.encodeComponent(schoolId)}';
      final requestUrl =
          '${ApiEndpoints.examApiBaseUrl}/$endpointWithQuery';
      print('📦 [SchoolContent] school_id: $schoolId');
      print('📦 [SchoolContent] GET $requestUrl');
      final response = await apiClient.get(endpointWithQuery);

      if (response.isSuccess && response.data != null) {
        final full = response.data as Map<String, dynamic>;
        if (full['status'] != 'success') {
          print('📦 [SchoolContent] Failed: ${full['message'] ?? response.error}');
          return;
        }
        final data = full['data'] as Map<String, dynamic>? ?? {};
        final videos = data['videos'] as List<dynamic>? ?? [];
        final pdfNotes = data['pdf_notes'] as List<dynamic>? ?? [];
        final zoomClasses = data['zoom_classes'] as List<dynamic>? ?? [];

        // Store in SQLite (same pattern as Firebase cache)
        await _saveSchoolContentToSqlite(schoolId, videos, pdfNotes, zoomClasses);

        await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
        print('📦 [SchoolContent] ==== DATA SET (saved to SQLite) ====');
        print('📦 [SchoolContent] videos: ${videos.length}');
        print('📦 [SchoolContent] pdf_notes: ${pdfNotes.length}');
        print('📦 [SchoolContent] zoom_classes: ${zoomClasses.length}');
        print('📦 [SchoolContent] ====================================');
      } else {
        print('📦 [SchoolContent] Failed: ${response.error}');
      }
    } catch (e) {
      print('📦 [SchoolContent] Error: $e');
    }
  }

  /// Converts API list items to DB docs (id + data JSON string) and saves to SQLite.
  static Future<void> _saveSchoolContentToSqlite(
    String schoolId,
    List<dynamic> videos,
    List<dynamic> pdfNotes,
    List<dynamic> zoomClasses,
  ) async {
    try {
      final videosDocs = _toCollectionDocs(videos);
      final pdfNotesDocs = _toCollectionDocs(pdfNotes);
      final zoomClassesDocs = _toCollectionDocs(zoomClasses);

      await SchoolCacheDatabase.replaceCollection(
        schoolId,
        'school_content_videos',
        videosDocs,
      );
      await SchoolCacheDatabase.replaceCollection(
        schoolId,
        'school_content_pdf_notes',
        pdfNotesDocs,
      );
      await SchoolCacheDatabase.replaceCollection(
        schoolId,
        'school_content_zoom_classes',
        zoomClassesDocs,
      );
    } catch (e) {
      print('📦 [SchoolContent] Error saving to SQLite: $e');
    }
  }

  static List<Map<String, dynamic>> _toCollectionDocs(List<dynamic> list) {
    return list.map((item) {
      final map = item is Map<String, dynamic>
          ? item
          : Map<String, dynamic>.from(item as Map);
      final id = map['id']?.toString() ?? map['_id']?.toString() ?? '';
      if (id.isEmpty) return null;
      return {'id': id, 'data': jsonEncode(map)};
    }).whereType<Map<String, dynamic>>().toList();
  }
}
