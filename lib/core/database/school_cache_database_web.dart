import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Browser/localStorage-backed cache mirroring [SchoolCacheDatabase] IO behavior.
/// No SQLite or path_provider on web.
class SchoolCacheDatabase {
  static const String _prefsKey = 'school_cache_state_v1';

  static const List<String> _collectionTables = [
    'app_config',
    'class_subjects',
    'classes',
    'enrollments',
    'invoices',
    'payments',
    'modules',
    'subjects',
    'teachers',
    'timetables',
    'school_content_videos',
    'school_content_pdf_notes',
    'school_content_zoom_classes',
  ];

  static Map<String, dynamic>? _root;
  static bool _loaded = false;

  static Map<String, dynamic> _emptyRoot() => {
        'sync': <String, dynamic>{},
        'tables': <String, dynamic>{},
        'profiles': <String, dynamic>{},
      };

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _root = Map<String, dynamic>.from(decoded);
        } else {
          _root = _emptyRoot();
        }
      } catch (_) {
        _root = _emptyRoot();
      }
    } else {
      _root = _emptyRoot();
    }
    _root!['sync'] ??= <String, dynamic>{};
    _root!['tables'] ??= <String, dynamic>{};
    _root!['profiles'] ??= <String, dynamic>{};
    _loaded = true;
  }

  static Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefsKey, jsonEncode(_root));
  }

  static Future<void> setDataVersion(String schoolId, int dataVersion) async {
    await _ensureLoaded();
    final sync = _root!['sync']! as Map<String, dynamic>;
    sync[schoolId] = dataVersion;
    await _persist();
  }

  static Future<int?> getDataVersion(String schoolId) async {
    await _ensureLoaded();
    final sync = _root!['sync']! as Map<String, dynamic>;
    final v = sync[schoolId];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static Future<void> replaceCollection(
    String schoolId,
    String collectionName,
    List<Map<String, dynamic>> docs,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    await _ensureLoaded();
    final tables = _root!['tables']! as Map<String, dynamic>;
    final col = tables.putIfAbsent(collectionName, () => <String, dynamic>{})
        as Map<String, dynamic>;
    final schoolMap = <String, dynamic>{};
    for (final doc in docs) {
      final id = doc['id'] as String? ?? doc['_id'] as String?;
      if (id == null) continue;
      final data = doc['data'] as String?;
      if (data == null) continue;
      schoolMap[id] = data;
    }
    col[schoolId] = schoolMap;
    await _persist();
  }

  static Future<void> upsertCollection(
    String schoolId,
    String collectionName,
    List<Map<String, dynamic>> docs,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    await _ensureLoaded();
    final tables = _root!['tables']! as Map<String, dynamic>;
    final col = tables.putIfAbsent(collectionName, () => <String, dynamic>{})
        as Map<String, dynamic>;
    final schoolMap = Map<String, dynamic>.from(
      col[schoolId] as Map<String, dynamic>? ?? {},
    );
    for (final doc in docs) {
      final id = doc['id'] as String? ?? doc['_id'] as String?;
      if (id == null) continue;
      final data = doc['data'] as String?;
      if (data == null) continue;
      schoolMap[id] = data;
    }
    col[schoolId] = schoolMap;
    await _persist();
  }

  static Future<List<Map<String, dynamic>>> getCollection(
    String schoolId,
    String collectionName,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    await _ensureLoaded();
    final tables = _root!['tables']! as Map<String, dynamic>;
    final col = tables[collectionName] as Map<String, dynamic>?;
    if (col == null) return [];
    final schoolMap = col[schoolId] as Map<String, dynamic>?;
    if (schoolMap == null) return [];
    return schoolMap.entries.map((e) {
      final id = e.key;
      final dataStr = e.value?.toString() ?? '{}';
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(jsonDecode(dataStr) as Map);
      } catch (_) {
        data = {};
      }
      data['id'] = id;
      return data;
    }).toList();
  }

  static Future<void> clearSchool(String schoolId) async {
    await _ensureLoaded();
    final sync = _root!['sync']! as Map<String, dynamic>;
    sync.remove(schoolId);
    final tables = _root!['tables']! as Map<String, dynamic>;
    for (final name in _collectionTables) {
      final col = tables[name] as Map<String, dynamic>?;
      col?.remove(schoolId);
    }
    await _persist();
  }

  static Future<void> clearAll() async {
    await _ensureLoaded();
    _root = _emptyRoot();
    await _persist();
  }

  static Future<void> close() async {
    _root = null;
    _loaded = false;
  }

  static Future<Map<String, dynamic>> studentProfileGet(String userId) async {
    if (userId.isEmpty) return {};
    await _ensureLoaded();
    final profiles = _root!['profiles']! as Map<String, dynamic>;
    final row = profiles[userId] as Map<String, dynamic>?;
    if (row == null) return {};
    final dataStr = row['data'] as String?;
    if (dataStr == null || dataStr.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(dataStr) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> studentProfilePut(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;
    await _ensureLoaded();
    final profiles = _root!['profiles']! as Map<String, dynamic>;
    profiles[userId] = {
      'data': jsonEncode(data),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _persist();
  }

  static Future<void> studentProfileDelete(String userId) async {
    if (userId.isEmpty) return;
    await _ensureLoaded();
    final profiles = _root!['profiles']! as Map<String, dynamic>;
    profiles.remove(userId);
    await _persist();
  }
}
