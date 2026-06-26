import 'package:cloud_firestore/cloud_firestore.dart';

/// Pushes student profile fields to Firestore without changing doc id or password.
/// Path: schools/{schoolId}/students/{documentId}
class StudentProfileFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Updates editable student fields. Does not update password or student_id.
  /// [documentId] is the students subcollection document id (same as login username / parent phone digits).
  static Future<void> updateStudentProfile({
    required String schoolId,
    required String documentId,
    required Map<String, dynamic> profile,
  }) async {
    if (schoolId.isEmpty || documentId.isEmpty) {
      throw ArgumentError('schoolId and documentId are required');
    }

    String s(String key) => (profile[key] ?? '').toString().trim();

    final update = <String, dynamic>{};

    void add(String firestoreKey, String value) {
      if (value.isNotEmpty) update[firestoreKey] = value;
    }

    add('full_name', s('full_name'));
    add('address', s('address'));
    add('date_of_birth', s('date_of_birth'));
    add('district', s('district'));
    add('gender', s('gender'));
    add('grade', s('grade'));
    add('parent_email', s('parent_email'));
    add('parent_phone', s('parent_phone'));
    add('parent_name', s('parent_name'));

    if (update.isEmpty) return;

    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('students')
        .doc(documentId)
        .update(update);
  }
}
