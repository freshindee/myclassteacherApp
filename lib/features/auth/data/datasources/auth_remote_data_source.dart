import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firestore,
  });

  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      final query = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
      if (query.docs.isEmpty) {
        throw Exception('User not found');
      }
      final userData = query.docs.first.data();
      if (userData['password'] != password) {
        throw Exception('Incorrect password');
      }
      return UserModel(
        id: query.docs.first.id,
        email: userData['email'],
        password: userData['password'],
      );
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp(String email, String password) async {
    try {
      // Check if user already exists
      final query = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
      if (query.docs.isNotEmpty) {
        throw Exception('User already exists');
      }
      final docRef = await firestore.collection('users').add({
        'email': email,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserModel(
        id: docRef.id,
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    // No-op for Firestore-only auth
    return;
  }
}