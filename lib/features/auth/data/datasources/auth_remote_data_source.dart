import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/crypto_service.dart';
import '../../../../core/utils/sri_lanka_phone_utils.dart';
import '../models/user_model.dart';
import '../models/sign_in_student_result_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String phoneNumber, String password, String teacherId);
  /// Student login: path schools/{schoolId}/students, match by student_id or admission_no and password.
  Future<SignInStudentResultModel> signInStudent(String schoolId, String username, String password);
  Future<UserModel> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
  );
  Future<void> signOut();
  Future<UserModel> updateUser({
    required String userId,
    String? phoneNumber,
    String? name,
    DateTime? birthday,
    String? district,
    String? newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore firestore;
  final CryptoService cryptoService;

  AuthRemoteDataSourceImpl({
    required this.firestore,
    required this.cryptoService,
  });

  @override
  Future<UserModel> signIn(String phoneNumber, String password, String teacherId) async {
    try {
      print('🔐 [API REQUEST] AuthDataSource.signIn called with:');
      print('🔐   - phoneNumber: $phoneNumber');
      print('🔐   - teacherId: $teacherId');
      print('🔐   - password: [HIDDEN]');
      
      print('🔐 [API REQUEST] Querying Firestore for user with phoneNumber: $phoneNumber and teacherId: $teacherId');
      
      final query = await firestore.collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .where('teacherId', isEqualTo: teacherId)
        .limit(1)
        .get();
      
      print('🔐 [API RESPONSE] Found ${query.docs.length} user documents');
      
      if (query.docs.isEmpty) {
        print('🔐 [API ERROR] No user found with phoneNumber: $phoneNumber and teacherId: $teacherId');
        throw Exception('Invalid credentials');
      }
      
      final userData = query.docs.first.data();
      print('🔐 [API RESPONSE] User document data: $userData');
      print('🔐 [API RESPONSE] Available fields: ${userData.keys.toList()}');
      print('🔐 [API RESPONSE] passwordHash: ${userData['passwordHash']}');
      print('🔐 [API RESPONSE] passwordSalt: ${userData['passwordSalt']}');
      print('🔐 [API RESPONSE] teacherId: ${userData['teacherId']}');
      print('🔐 [API RESPONSE] phoneNumber: ${userData['phoneNumber']}');
      print('🔐 [API RESPONSE] name: ${userData['name']}');
      print('🔐 [API RESPONSE] district: ${userData['district']}');
      print('🔐 [API RESPONSE] birthday: ${userData['birthday']}');
      
      // Verify password - check if we have passwordHash and passwordSalt
      final passwordHash = userData['passwordHash'] as String?;
      final passwordSalt = userData['passwordSalt'] as String?;
      
      if (passwordHash == null || passwordSalt == null) {
        print('🔐 [API ERROR] Password hash or salt not found for user with phoneNumber: $phoneNumber');
        throw Exception('Invalid user data');
      }
      
      // Hash the provided password with the stored salt and compare
      final hashedPassword = await cryptoService.hashPassword(password, passwordSalt);
      final isPasswordValid = hashedPassword == passwordHash;
      
      if (!isPasswordValid) {
        print('🔐 [API ERROR] Invalid password for user with phoneNumber: $phoneNumber');
        throw Exception('Invalid credentials');
      }
      
      print('🔐 [API RESPONSE] Password verified successfully');
      
      // Safely extract fields with null checks
      final extractedPhoneNumber = userData['phoneNumber'] as String? ?? '';
      
      // Try to get plain fields first, if not available, try to decrypt encrypted fields
      String? name = userData['name'] as String?;
      if (name == null || name.isEmpty) {
        // Try to decrypt encrypted name
        try {
          final nameEnc = userData['nameEnc'] as String?;
          final nameNonce = userData['nameNonce'] as String?;
          final nameMac = userData['nameMac'] as String?;
          if (nameEnc != null && nameNonce != null && nameMac != null) {
            name = await cryptoService.decryptField(
              ciphertextBase64: nameEnc,
              nonceBase64: nameNonce,
              macBase64: nameMac,
            );
          }
        } catch (e) {
          print('🔐 [API WARNING] Failed to decrypt name: $e');
          name = '';
        }
      }
      
      DateTime? birthday;
      try {
        final birthdayStr = userData['birthday'] as String?;
        if (birthdayStr != null) {
          birthday = DateTime.parse(birthdayStr);
        } else {
          // Try to decrypt encrypted birthday
          final birthdayEnc = userData['birthdayEnc'] as String?;
          final birthdayNonce = userData['birthdayNonce'] as String?;
          final birthdayMac = userData['birthdayMac'] as String?;
          if (birthdayEnc != null && birthdayNonce != null && birthdayMac != null) {
            final decryptedBirthday = await cryptoService.decryptField(
              ciphertextBase64: birthdayEnc,
              nonceBase64: birthdayNonce,
              macBase64: birthdayMac,
            );
            birthday = DateTime.parse(decryptedBirthday);
          }
        }
      } catch (e) {
        print('🔐 [API WARNING] Failed to parse birthday: $e');
        birthday = null;
      }
      
      String? district = userData['district'] as String?;
      if (district == null || district.isEmpty) {
        // Try to decrypt encrypted district
        try {
          final districtEnc = userData['districtEnc'] as String?;
          final districtNonce = userData['districtNonce'] as String?;
          final districtMac = userData['districtMac'] as String?;
          if (districtEnc != null && districtNonce != null && districtMac != null) {
            district = await cryptoService.decryptField(
              ciphertextBase64: districtEnc,
              nonceBase64: districtNonce,
              macBase64: districtMac,
            );
          }
        } catch (e) {
          print('🔐 [API WARNING] Failed to decrypt district: $e');
          district = '';
        }
      }
      
      final extractedTeacherId = userData['teacherId'] as String? ?? '';
      
      final userModel = UserModel(
        userId: query.docs.first.id,
        phoneNumber: extractedPhoneNumber,
        password: '', // Don't store plain password in memory
        name: name,
        birthday: birthday,
        district: district,
        teacherId: extractedTeacherId,
      );
      
      print('🔐 [API RESPONSE] Successfully created UserModel: ${userModel.name}');
      return userModel;
    } catch (e) {
      print('🔐 [API ERROR] Error during sign in: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<SignInStudentResultModel> signInStudent(String schoolId, String username, String password) async {
    try {
      final trimmedSchoolId = schoolId.trim();
      final inputPassword = password.trim();
      if (trimmedSchoolId.isEmpty || inputPassword.isEmpty) {
        throw Exception('Invalid credentials');
      }

      // 1. Parent's mobile: Sri Lanka format → local 07…, then match students/{documentId} (10-digit or legacy 9-digit id).
      // 2. Verify password from that document.
      final local = SriLankaPhoneUtils.normalizeToLocalTenDigits(username);
      if (local == null) {
        print('🔐 [API ERROR] Invalid Sri Lanka mobile number');
        throw Exception('Invalid credentials');
      }
      final candidates = SriLankaPhoneUtils.candidateStudentDocumentIds(local);
      print('🔐 [API REQUEST] AuthDataSource.signInStudent schoolId: $trimmedSchoolId, local: $local, mobile candidates: $candidates');
      final studentsRef = firestore.collection('schools').doc(trimmedSchoolId).collection('students');
      final docSnapshot = await _findStudentDocument(studentsRef, local, candidates);
      if (docSnapshot == null || !docSnapshot.exists) {
        print('🔐 [API ERROR] No student found for schoolId: $trimmedSchoolId, local: $local, candidates: $candidates');
        throw Exception('Invalid credentials');
      }
      final data = docSnapshot.data();
      if (data == null) {
        throw Exception('Invalid credentials');
      }
      final storedPassword = data['password']?.toString().trim();
      if (storedPassword == null || storedPassword.isEmpty || storedPassword != inputPassword) {
        print('🔐 [API ERROR] Invalid password for student ${docSnapshot.id}');
        throw Exception('Invalid credentials');
      }
      final studentId = data['student_id'] as String? ?? docSnapshot.id;
      final fullName = data['full_name'] as String? ?? '';
      final address = data['address'] as String?;
      final dateOfBirthStr = data['date_of_birth'] as String?;
      DateTime? birthday;
      if (dateOfBirthStr != null && dateOfBirthStr.isNotEmpty) {
        try {
          birthday = DateTime.parse(dateOfBirthStr);
        } catch (_) {}
      }
      final userModel = UserModel(
        userId: studentId,
        phoneNumber: '',
        password: password,
        name: fullName,
        birthday: birthday,
        district: address,
        teacherId: trimmedSchoolId,
      );
      // Full student document for local storage (exclude password). Convert Timestamp to string for JSON.
      // firestore_document_id = students subcollection doc id (login username = parent phone digits only).
      final rawDetails = Map<String, dynamic>.from(data)
        ..['school_id'] = trimmedSchoolId
        ..['firestore_document_id'] = docSnapshot.id
        ..remove('password');

      // Hero texts from parent school document: schools/{schoolId}
      try {
        final schoolSnap =
            await firestore.collection('schools').doc(trimmedSchoolId).get();
        final schoolData = schoolSnap.data();
        final schoolName = schoolData?['school_name'];
        final headingText = schoolData?['heading_text'];
        final todayMessage = schoolData?['today_message'];
        if (schoolName != null && schoolName.toString().trim().isNotEmpty) {
          rawDetails['school_name'] = schoolName.toString().trim();
        }
        if (headingText != null && headingText.toString().trim().isNotEmpty) {
          rawDetails['heading_text'] = headingText.toString().trim();
        }
        if (todayMessage != null && todayMessage.toString().trim().isNotEmpty) {
          rawDetails['today_message'] = todayMessage.toString().trim();
        }
      } catch (e) {
        print('🔐 [API WARN] signInStudent: could not load schools/$trimmedSchoolId hero fields: $e');
      }

      final studentDetails = _mapToJsonEncodable(rawDetails);
      return SignInStudentResultModel(user: userModel, studentDetails: studentDetails);
    } catch (e) {
      print('🔐 [API ERROR] signInStudent: $e');
      rethrow;
    }
  }

  /// Finds a student by document id, then falls back to [parent_phone] / [student_id] fields.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _findStudentDocument(
    CollectionReference<Map<String, dynamic>> studentsRef,
    String localTenDigits,
    List<String> documentIdCandidates,
  ) async {
    for (final documentId in documentIdCandidates) {
      final snap = await studentsRef.doc(documentId).get();
      if (snap.exists) return snap;
    }

    final lookupValues = <String>{
      localTenDigits,
      if (localTenDigits.length == 10) localTenDigits.substring(1),
    };
    for (final value in lookupValues) {
      for (final field in const ['parent_phone', 'student_id']) {
        final query = await studentsRef
            .where(field, isEqualTo: value)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) return query.docs.first;
      }
    }

    return null;
  }

  /// Converts Firestore Timestamp (and nested values) to JSON-encodable form.
  static Map<String, dynamic> _mapToJsonEncodable(Map<String, dynamic> map) {
    return map.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      if (value is Map) {
        return MapEntry(key, _mapToJsonEncodable(Map<String, dynamic>.from(value)));
      }
      if (value is List) {
        return MapEntry(
          key,
          value.map((e) {
            if (e is Timestamp) return e.toDate().toIso8601String();
            if (e is Map) return _mapToJsonEncodable(Map<String, dynamic>.from(e));
            return e;
          }).toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  @override
  Future<UserModel> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
  ) async {
    try {
      // Check if user already exists
      final query = await firestore.collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        throw Exception('User already exists');
      }
      // Use phoneNumber as document ID
      // Prepare password hash + salt
      final saltB64 = cryptoService.generateSaltBase64(length: 16);
      final hashB64 = await cryptoService.hashPassword(password, saltB64);

      // Encrypt optional PII fields
      Map<String, dynamic> encryptedFields = {};
      if (name != null && name.isNotEmpty) {
        final enc = await cryptoService.encryptField(name);
        encryptedFields.addAll({
          'nameEnc': enc['ciphertext'],
          'nameNonce': enc['nonce'],
          'nameMac': enc['mac'],
        });
      }
      if (district != null && district.isNotEmpty) {
        final enc = await cryptoService.encryptField(district);
        encryptedFields.addAll({
          'districtEnc': enc['ciphertext'],
          'districtNonce': enc['nonce'],
          'districtMac': enc['mac'],
        });
      }
      if (birthday != null) {
        final enc = await cryptoService.encryptField(birthday.toIso8601String());
        encryptedFields.addAll({
          'birthdayEnc': enc['ciphertext'],
          'birthdayNonce': enc['nonce'],
          'birthdayMac': enc['mac'],
        });
      }

      await firestore.collection('users').doc(phoneNumber).set({
        'userId': phoneNumber,
        'phoneNumber': phoneNumber,
        'passwordHash': hashB64,
        'passwordSalt': saltB64,
        'teacherId': teacherId,
        // keep plaintext fields absent to avoid leaking
        ...encryptedFields,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserModel(
        userId: phoneNumber,
        phoneNumber: phoneNumber,
        password: '',
        name: name,
        birthday: birthday,
        district: district,
        teacherId: teacherId,
      );
    } catch (e) {
      throw Exception('Failed to sign up:  [${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    // No-op for Firestore-only auth
    return;
  }

  @override
  Future<UserModel> updateUser({
    required String userId,
    String? phoneNumber,
    String? name,
    DateTime? birthday,
    String? district,
    String? newPassword,
  }) async {
    // Resolve the correct document reference. userId may be a field value, not the doc id.
    DocumentReference<Map<String, dynamic>> userRef = firestore.collection('users').doc(userId);
    DocumentSnapshot<Map<String, dynamic>> existing = await userRef.get();
    if (!existing.exists) {
      // Try by 'userId' field
      final byUserId = await firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (byUserId.docs.isNotEmpty) {
        userRef = byUserId.docs.first.reference;
      } else {
        // Try by phoneNumber field
        final byPhone = await firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: userId)
            .limit(1)
            .get();
        if (byPhone.docs.isNotEmpty) {
          userRef = byPhone.docs.first.reference;
        }
      }
    }
    final Map<String, dynamic> updates = {};
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      updates['phoneNumber'] = phoneNumber;
      updates['userId'] = phoneNumber;
    }
    if (name != null) {
      final enc = await cryptoService.encryptField(name);
      updates.addAll({
        'nameEnc': enc['ciphertext'],
        'nameNonce': enc['nonce'],
        'nameMac': enc['mac'],
        'name': FieldValue.delete(),
      });
    }
    if (district != null) {
      final enc = await cryptoService.encryptField(district);
      updates.addAll({
        'districtEnc': enc['ciphertext'],
        'districtNonce': enc['nonce'],
        'districtMac': enc['mac'],
        'district': FieldValue.delete(),
      });
    }
    if (birthday != null) {
      final enc = await cryptoService.encryptField(birthday.toIso8601String());
      updates.addAll({
        'birthdayEnc': enc['ciphertext'],
        'birthdayNonce': enc['nonce'],
        'birthdayMac': enc['mac'],
        'birthday': FieldValue.delete(),
      });
    }
    if (newPassword != null && newPassword.isNotEmpty) {
      final saltB64 = cryptoService.generateSaltBase64(length: 16);
      final hashB64 = await cryptoService.hashPassword(newPassword, saltB64);
      updates.addAll({
        'passwordHash': hashB64,
        'passwordSalt': saltB64,
        'password': FieldValue.delete(),
      });
    }

    if (updates.isNotEmpty) {
      await userRef.update(updates);
    }

    final snap = await userRef.get();
    final data = snap.data() ?? {};
    String? decName;
    String? decDistrict;
    DateTime? decBirthday;
    try {
      if (data['nameEnc'] != null && data['nameNonce'] != null && data['nameMac'] != null) {
        decName = await cryptoService.decryptField(
          ciphertextBase64: data['nameEnc'],
          nonceBase64: data['nameNonce'],
          macBase64: data['nameMac'],
        );
      } else {
        decName = data['name'];
      }
      if (data['districtEnc'] != null && data['districtNonce'] != null && data['districtMac'] != null) {
        decDistrict = await cryptoService.decryptField(
          ciphertextBase64: data['districtEnc'],
          nonceBase64: data['districtNonce'],
          macBase64: data['districtMac'],
        );
      } else {
        decDistrict = data['district'];
      }
      if (data['birthdayEnc'] != null && data['birthdayNonce'] != null && data['birthdayMac'] != null) {
        final bdayStr = await cryptoService.decryptField(
          ciphertextBase64: data['birthdayEnc'],
          nonceBase64: data['birthdayNonce'],
          macBase64: data['birthdayMac'],
        );
        decBirthday = DateTime.tryParse(bdayStr);
      } else if (data['birthday'] != null) {
        decBirthday = DateTime.tryParse(data['birthday']);
      }
    } catch (_) {}

    return UserModel(
      userId: data['userId'] ?? userId,
      phoneNumber: data['phoneNumber'] ?? phoneNumber ?? userId,
      password: '',
      name: decName,
      birthday: decBirthday,
      district: decDistrict,
    );
  }
}