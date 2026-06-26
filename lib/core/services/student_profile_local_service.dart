import '../database/school_cache_database.dart';

/// Local persistence for student profile (aligned with school students table shape).
/// Keys: student_id, full_name, address, date_of_birth, district, gender, grade,
/// parent_email, parent_phone, parent_name, status, created_at, joined_date.
class StudentProfileLocalService {
  /// Load profile for user; returns empty map if none.
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    if (userId.isEmpty) return {};
    return SchoolCacheDatabase.studentProfileGet(userId);
  }

  /// Save full profile map (replaces stored data).
  static Future<void> saveProfile(String userId, Map<String, dynamic> data) async {
    if (userId.isEmpty) return;
    await SchoolCacheDatabase.studentProfilePut(userId, data);
  }

  /// Merge [incoming] into existing profile (incoming wins on key overlap).
  /// Normalizes keys from Firestore/sign-in payload (e.g. full_name, date_of_birth).
  static Future<Map<String, dynamic>> mergeFromStudentDetails(
    String userId,
    Map<String, dynamic> incoming,
  ) async {
    final existing = await getProfile(userId);
    final merged = Map<String, dynamic>.from(existing);

    void put(String canonicalKey, dynamic value) {
      if (value == null) return;
      final s = value.toString().trim();
      if (s.isEmpty) return;
      merged[canonicalKey] = s;
    }

    put('student_id', incoming['student_id'] ?? incoming['studentId']);
    put('full_name', incoming['full_name'] ?? incoming['fullName'] ?? incoming['name']);
    put('address', incoming['address']);
    put('date_of_birth', incoming['date_of_birth'] ?? incoming['dateOfBirth'] ?? incoming['birthday']);
    put('district', incoming['district']);
    put('gender', incoming['gender']);
    put('grade', incoming['grade']);
    put('parent_email', incoming['parent_email'] ?? incoming['parentEmail']);
    put('parent_phone', incoming['parent_phone'] ?? incoming['parentPhone']);
    put('parent_name', incoming['parent_name'] ?? incoming['parentName']);
    put('status', incoming['status']);
    put('created_at', incoming['created_at'] ?? incoming['createdAt']);
    put('joined_date', incoming['joined_date'] ?? incoming['joinedDate']);
    final docId = incoming['firestore_document_id'] ?? incoming['firestoreDocumentId'];
    if (docId != null && docId.toString().trim().isNotEmpty) {
      merged['firestore_document_id'] = docId.toString().trim();
    }

    await saveProfile(userId, merged);
    return merged;
  }

  static Future<void> deleteProfile(String userId) async {
    if (userId.isEmpty) return;
    await SchoolCacheDatabase.studentProfileDelete(userId);
  }
}
