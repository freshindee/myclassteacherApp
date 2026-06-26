import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite cache for school master data (students app only).
class SchoolCacheDatabase {
  static const String _dbName = 'school_cache.db';
  static const int _version = 5;

  static const List<String> timetablesColumns = [
    'academic_year',
    'chapter_name',
    'class_id',
    'class_subject_id',
    'created_at',
    'day',
    'day_of_week',
    'end_time',
    'grade',
    'room',
    'start_time',
    'status',
    'subject',
    'subject_id',
    'teacher',
    'teacher_id',
  ];

  static Database? _db;

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

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final documents = await getApplicationDocumentsDirectory();
    final dbPath = join(documents.path, _dbName);
    return openDatabase(
      dbPath,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final table in ['school_content_videos', 'school_content_pdf_notes', 'school_content_zoom_classes']) {
        await db.execute('''
          CREATE TABLE $table (
            school_id TEXT NOT NULL,
            id TEXT NOT NULL,
            data TEXT NOT NULL,
            PRIMARY KEY (school_id, id)
          )
        ''');
        await db.execute('CREATE INDEX idx_${table}_school ON $table (school_id)');
      }
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE payments (
          school_id TEXT NOT NULL,
          id TEXT NOT NULL,
          data TEXT NOT NULL,
          PRIMARY KEY (school_id, id)
        )
      ''');
      await db.execute('CREATE INDEX idx_payments_school ON payments (school_id)');
    }
    if (oldVersion < 4) {
      for (final col in timetablesColumns) {
        try {
          await db.execute('ALTER TABLE timetables ADD COLUMN $col TEXT');
        } catch (_) {}
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE student_profile (
          user_id TEXT PRIMARY KEY,
          data TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_metadata (
        school_id TEXT PRIMARY KEY,
        data_version INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT
      )
    ''');

    for (final table in _collectionTables) {
      await db.execute('''
        CREATE TABLE $table (
          school_id TEXT NOT NULL,
          id TEXT NOT NULL,
          data TEXT NOT NULL,
          PRIMARY KEY (school_id, id)
        )
      ''');
      await db.execute('CREATE INDEX idx_${table}_school ON $table (school_id)');
    }

    await db.execute('''
      CREATE TABLE student_profile (
        user_id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }

  static Future<void> setDataVersion(String schoolId, int dataVersion) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {
        'school_id': schoolId,
        'data_version': dataVersion,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int?> getDataVersion(String schoolId) async {
    final db = await database;
    final rows = await db.query(
      'sync_metadata',
      columns: ['data_version'],
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    if (rows.isEmpty) return null;
    return rows.first['data_version'] as int?;
  }

  static Future<void> replaceCollection(
    String schoolId,
    String collectionName,
    List<Map<String, dynamic>> docs,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    final db = await database;
    final batch = db.batch();
    await db.delete(collectionName, where: 'school_id = ?', whereArgs: [schoolId]);
    for (final doc in docs) {
      final id = doc['id'] as String? ?? doc['_id'] as String?;
      if (id == null) continue;
      final data = doc['data'] as String?;
      if (data == null) continue;
      batch.insert(collectionName, {
        'school_id': schoolId,
        'id': id,
        'data': data,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> upsertCollection(
    String schoolId,
    String collectionName,
    List<Map<String, dynamic>> docs,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    final db = await database;
    final batch = db.batch();
    for (final doc in docs) {
      final id = doc['id'] as String? ?? doc['_id'] as String?;
      if (id == null) continue;
      final data = doc['data'] as String?;
      if (data == null) continue;
      batch.insert(
        collectionName,
        {'school_id': schoolId, 'id': id, 'data': data},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCollection(
    String schoolId,
    String collectionName,
  ) async {
    if (!_collectionTables.contains(collectionName)) {
      throw ArgumentError('Unknown collection: $collectionName');
    }
    final db = await database;
    final rows = await db.query(
      collectionName,
      where: 'school_id = ?',
      whereArgs: [schoolId],
    );
    return rows.map((row) {
      final id = row['id'] as String? ?? '';
      final dataStr = row['data'] as String? ?? '{}';
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
    final db = await database;
    final batch = db.batch();
    batch.delete('sync_metadata', where: 'school_id = ?', whereArgs: [schoolId]);
    for (final table in _collectionTables) {
      batch.delete(table, where: 'school_id = ?', whereArgs: [schoolId]);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> clearAll() async {
    final db = await database;
    for (final table in ['sync_metadata', ..._collectionTables, 'student_profile']) {
      await db.delete(table);
    }
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<Map<String, dynamic>> studentProfileGet(String userId) async {
    if (userId.isEmpty) return {};
    final db = await database;
    final rows = await db.query(
      'student_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return {};
    final dataStr = rows.first['data'] as String?;
    if (dataStr == null || dataStr.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(dataStr) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> studentProfilePut(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;
    final db = await database;
    await db.insert(
      'student_profile',
      {
        'user_id': userId,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> studentProfileDelete(String userId) async {
    if (userId.isEmpty) return;
    final db = await database;
    await db.delete('student_profile', where: 'user_id = ?', whereArgs: [userId]);
  }
}
