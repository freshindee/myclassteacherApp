import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:classes/core/services/crypto_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String phoneNumber, String password);
  Future<UserModel> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
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
  Future<UserModel> signIn(String phoneNumber, String password) async {
    try {
      print('🔐 AuthDataSource: Attempting sign in for phoneNumber: $phoneNumber');
      
      final query = await firestore.collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
      
      if (query.docs.isEmpty) {
        print('❌ AuthDataSource: User not found for phoneNumber: $phoneNumber');
        throw Exception('User not found');
      }
      
      final userData = query.docs.first.data();
      final documentId = query.docs.first.id;
      
      print('🔐 AuthDataSource: Found user document:');
      print('🔐   - Document ID: $documentId');
      print('🔐   - User data: $userData');
      
      // Verify password (supports new hashed scheme and legacy plaintext fallback)
      final String? passwordHash = userData['passwordHash'] as String?;
      final String? passwordSalt = userData['passwordSalt'] as String?;
      if (passwordHash != null && passwordSalt != null) {
        final computed = await cryptoService.hashPassword(password, passwordSalt);
        if (computed != passwordHash) {
          print('❌ AuthDataSource: Incorrect password (hashed) for phoneNumber: $phoneNumber');
          throw Exception('Incorrect password');
        }
      } else {
        // Legacy fallback
        if (userData['password'] != password) {
          print('❌ AuthDataSource: Incorrect password (legacy) for phoneNumber: $phoneNumber');
          throw Exception('Incorrect password');
        }
      }
      
      // Check if there's a specific userId field in the document
      final actualUserId = userData['userId'] ?? userData['id'] ?? documentId;
      
      print('🔐 AuthDataSource: Using userId: $actualUserId');
      print('🔐   - From userId field: ${userData['userId']}');
      print('🔐   - From id field: ${userData['id']}');
      print('🔐   - From document ID: $documentId');
      
      // Decrypt PII fields if encrypted; otherwise use plaintext
      String? name;
      String? district;
      DateTime? birthday;
      try {
        if (userData['nameEnc'] != null && userData['nameNonce'] != null && userData['nameMac'] != null) {
          name = await cryptoService.decryptField(
            ciphertextBase64: userData['nameEnc'],
            nonceBase64: userData['nameNonce'],
            macBase64: userData['nameMac'],
          );
        } else {
          name = userData['name'];
        }
        if (userData['districtEnc'] != null && userData['districtNonce'] != null && userData['districtMac'] != null) {
          district = await cryptoService.decryptField(
            ciphertextBase64: userData['districtEnc'],
            nonceBase64: userData['districtNonce'],
            macBase64: userData['districtMac'],
          );
        } else {
          district = userData['district'];
        }
        if (userData['birthdayEnc'] != null && userData['birthdayNonce'] != null && userData['birthdayMac'] != null) {
          final bdayStr = await cryptoService.decryptField(
            ciphertextBase64: userData['birthdayEnc'],
            nonceBase64: userData['birthdayNonce'],
            macBase64: userData['birthdayMac'],
          );
          birthday = DateTime.tryParse(bdayStr);
        } else if (userData['birthday'] != null) {
          birthday = DateTime.parse(userData['birthday']);
        }
      } catch (e) {
        print('⚠️ AuthDataSource: Decryption failed, falling back to plaintext fields if available. Error: $e');
        name = name ?? userData['name'];
        district = district ?? userData['district'];
        if (birthday == null && userData['birthday'] != null) {
          birthday = DateTime.tryParse(userData['birthday']);
        }
      }

      return UserModel(
        userId: actualUserId,
        phoneNumber: userData['phoneNumber'],
        password: '',
        name: name,
        birthday: birthday,
        district: district,
      );
    } catch (e) {
      print('❌ AuthDataSource: Sign in failed: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
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