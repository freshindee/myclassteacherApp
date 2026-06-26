import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/sri_lanka_phone_utils.dart';

/// Firestore checks for school / student registration.
class SchoolValidationService {
  SchoolValidationService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// `null` if valid; otherwise a short error message.
  static String? validateSchoolIdFormat(String? schoolId) {
    final id = schoolId?.trim() ?? '';
    if (id.isEmpty) {
      return 'School ID / Teacher ID is required';
    }
    if (id.length != 6) {
      return 'School ID / Teacher ID must be exactly 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      return 'School ID / Teacher ID must contain only numbers';
    }
    return null;
  }

  /// Returns `true` when [schoolId] maps to an existing school in Firestore.
  static Future<bool> schoolExists(String schoolId) async {
    final id = schoolId.trim();
    if (id.isEmpty) return false;

    final schoolRef = _firestore.collection('schools').doc(id);
    final schoolSnap = await schoolRef.get();
    if (schoolSnap.exists) return true;

    final appConfigSnap = await schoolRef.collection('app_config').limit(1).get();
    return appConfigSnap.docs.isNotEmpty;
  }

  /// Returns `true` when a student with [localTenDigits] already exists under [schoolId].
  static Future<bool> studentExists(
    String schoolId,
    String localTenDigits,
  ) async {
    final id = schoolId.trim();
    if (id.isEmpty || !SriLankaPhoneUtils.isValidRegistrationLocalTenDigits(localTenDigits)) {
      return false;
    }

    final studentsRef =
        _firestore.collection('schools').doc(id).collection('students');
    for (final documentId
        in SriLankaPhoneUtils.candidateStudentDocumentIds(localTenDigits)) {
      final snap = await studentsRef.doc(documentId).get();
      if (snap.exists) return true;
    }
    return false;
  }
}
