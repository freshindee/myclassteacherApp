import '../database/school_cache_database.dart';

/// Cached app_config document shape: bank_details, data_version, sliderImages, update_the_app.
class AppConfigMap {
  final List<String> bankDetails;
  final int dataVersion;
  final List<String> sliderImages;
  final bool updateTheApp;

  const AppConfigMap({
    this.bankDetails = const [],
    this.dataVersion = 0,
    this.sliderImages = const [],
    this.updateTheApp = false,
  });

  factory AppConfigMap.fromMap(Map<String, dynamic> map) {
    final bankDetailsList = map['bank_details'] as List<dynamic>? ?? [];
    final sliderList = map['sliderImages'] as List<dynamic>? ?? [];
    final v = map['data_version'];
    int dataVersion = 0;
    if (v != null) {
      if (v is int) dataVersion = v;
      else if (v is num) dataVersion = v.toInt();
    }
    return AppConfigMap(
      bankDetails: bankDetailsList.map((e) => e.toString()).toList(),
      dataVersion: dataVersion,
      sliderImages: sliderList.map((e) => e.toString()).toList(),
      updateTheApp: map['update_the_app'] == true || map['updateTheApp'] == true,
    );
  }
}

/// Read-only access to school master data cached in SQLite (students app).
/// Use this in screens when you need app_config, class_subjects, classes, enrollments, invoices, modules, subjects, teachers, timetables.
class SchoolCacheService {
  /// Returns all documents from app_config for the school.
  Future<List<Map<String, dynamic>>> getAppConfig(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'app_config');
  }

  /// Returns the single app_config document for the school (first doc).
  /// Shape: bank_details (List<String>), data_version (int), sliderImages (List<String>), update_the_app (bool).
  Future<AppConfigMap?> getAppConfigSingle(String schoolId) async {
    final docs = await getAppConfig(schoolId);
    if (docs.isEmpty) return null;
    return AppConfigMap.fromMap(docs.first);
  }

  /// Returns data_version from app_config if present (from first doc that has it).
  Future<int?> getDataVersion(String schoolId) async {
    final config = await getAppConfigSingle(schoolId);
    return config?.dataVersion;
  }

  Future<List<Map<String, dynamic>>> getClassSubjects(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'class_subjects');
  }

  /// Returns unique grade values from class_subjects (uses 'grade' or 'grade_name' field).
  Future<List<String>> getGradesFromClassSubjects(String schoolId) async {
    final all = await getClassSubjects(schoolId);
    final grades = <String>{};
    for (final doc in all) {
      final grade = doc['grade'] ?? doc['grade_name'] ?? doc['name'];
      if (grade != null && grade.toString().trim().isNotEmpty) {
        grades.add(grade.toString().trim());
      }
    }
    return grades.toList()..sort();
  }

  /// Returns class_subjects for the given grade (filters by 'grade' or 'grade_name').
  Future<List<Map<String, dynamic>>> getClassSubjectsByGrade(
    String schoolId,
    String grade,
  ) async {
    final all = await getClassSubjects(schoolId);
    return all.where((doc) {
      final g = doc['grade'] ?? doc['grade_name'] ?? doc['name'];
      return g != null && g.toString().trim() == grade.trim();
    }).toList();
  }

  /// Returns class_subjects for the selected class from local DB.
  /// Filters by class_id, or class_name, or class (supports common schema variants).
  Future<List<Map<String, dynamic>>> getClassSubjectsForClass(
    String schoolId,
    String classId,
    String className,
  ) async {
    final all = await getClassSubjects(schoolId);
    return all.where((doc) {
      final docClassId = doc['class_id'] ?? doc['classId'] ?? doc['class'];
      final docClassName = doc['class_name'] ?? doc['className'] ?? doc['class'];
      if (docClassId != null && docClassId.toString().trim() == classId.trim()) return true;
      if (docClassName != null && docClassName.toString().trim() == className.trim()) return true;
      return false;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getClasses(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'classes');
  }

  /// Returns all classes from the cached `classes` table whose grade matches
  /// [gradeNumber] (e.g. "5"). Each map has id, name, etc. Use for a selectable list.
  Future<List<Map<String, dynamic>>> getClassesByGradeNumber(
    String schoolId,
    String gradeNumber,
  ) async {
    final classes = await getClasses(schoolId);
    final normalized = gradeNumber.trim();
    return classes.where((c) {
      final g = c['grade'] ?? c['grade_number'] ?? c['grade_id'];
      if (g == null) return false;
      return g.toString().trim() == normalized;
    }).toList();
  }

  /// Display name for a class document (name, class_name, title, or "Grade X").
  static String classDisplayName(Map<String, dynamic> classDoc, String fallbackGrade) {
    final name = classDoc['name'] ?? classDoc['class_name'] ?? classDoc['title'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }
    return 'Grade $fallbackGrade';
  }

  Future<List<Map<String, dynamic>>> getEnrollments(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'enrollments');
  }

  Future<List<Map<String, dynamic>>> getInvoices(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'invoices');
  }

  /// Returns cached payments for the school (from Firestore schools/{schoolId}/payments).
  Future<List<Map<String, dynamic>>> getPayments(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'payments');
  }

  Future<List<Map<String, dynamic>>> getModules(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'modules');
  }

  Future<List<Map<String, dynamic>>> getSubjects(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'subjects');
  }

  /// Returns the display name for a subject from the subjects table by id.
  /// Uses 'subject', 'name', or 'title' field. Returns null if not found.
  Future<String?> getSubjectNameById(String schoolId, String subjectId) async {
    if (subjectId.trim().isEmpty) return null;
    final subjects = await getSubjects(schoolId);
    for (final s in subjects) {
      final id = s['id']?.toString();
      if (id == null) continue;
      if (id.trim() == subjectId.trim()) {
        final name = s['subject'] ?? s['name'] ?? s['title'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
        return null;
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getTeachers(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'teachers');
  }

  /// Returns cached timetables for the school. Each map may include: academic_year, class_id, class_subject_id,
  /// day, day_of_week, start_time, end_time, grade, room, status, subject, subject_id, teacher, teacher_id.
  Future<List<Map<String, dynamic>>> getTimetables(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'timetables');
  }

  // --- School content from get_school_content.php API (cached in SQLite) ---

  /// Returns cached videos for the school (id, class_subject_id, title, video_url, access_level).
  Future<List<Map<String, dynamic>>> getSchoolContentVideos(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'school_content_videos');
  }

  /// Returns cached pdf_notes for the school (id, class_subject_id, title, pdf_url, access_level).
  Future<List<Map<String, dynamic>>> getSchoolContentPdfNotes(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'school_content_pdf_notes');
  }

  /// Returns cached zoom_classes for the school (id, class_subject_id, title, zoom_meeting_id, zoom_password, join_url, class_day, start_time, end_time, access_level).
  Future<List<Map<String, dynamic>>> getSchoolContentZoomClasses(String schoolId) async {
    return SchoolCacheDatabase.getCollection(schoolId, 'school_content_zoom_classes');
  }

  /// Clears cached data for this school (e.g. on logout).
  Future<void> clearSchool(String schoolId) async {
    await SchoolCacheDatabase.clearSchool(schoolId);
  }
}
