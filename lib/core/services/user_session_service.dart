import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user.dart';

class UserSessionService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user session
  static Future<void> saveUserSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'userId': user.userId,
      'phoneNumber': user.phoneNumber,
      'password': user.password,
    }));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get current user session
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn || userJson == null) {
      return null;
    }
    try {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User(
        userId: userMap['userId'],
        phoneNumber: userMap['phoneNumber'],
        password: userMap['password'],
      );
    } catch (e) {
      // If there's an error parsing the user data, clear the session
      await clearUserSession();
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user session
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final user = await getCurrentUser();
    return user?.userId;
  }
} 