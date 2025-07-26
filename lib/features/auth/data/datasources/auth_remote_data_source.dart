import 'package:cloud_firestore/cloud_firestore.dart';
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
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firestore,
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
      
      if (userData['password'] != password) {
        print('❌ AuthDataSource: Incorrect password for phoneNumber: $phoneNumber');
        throw Exception('Incorrect password');
      }
      
      // Check if there's a specific userId field in the document
      final actualUserId = userData['userId'] ?? userData['id'] ?? documentId;
      
      print('🔐 AuthDataSource: Using userId: $actualUserId');
      print('🔐   - From userId field: ${userData['userId']}');
      print('🔐   - From id field: ${userData['id']}');
      print('🔐   - From document ID: $documentId');
      
      return UserModel(
        userId: actualUserId,
        phoneNumber: userData['phoneNumber'],
        password: userData['password'],
        name: userData['name'],
        birthday: userData['birthday'] != null ? DateTime.parse(userData['birthday']) : null,
        district: userData['district'],
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
      await firestore.collection('users').doc(phoneNumber).set({
        'userId': phoneNumber,
        'phoneNumber': phoneNumber,
        'password': password,
        'name': name,
        'birthday': birthday?.toIso8601String(),
        'district': district,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserModel(
        userId: phoneNumber,
        phoneNumber: phoneNumber,
        password: password,
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
}