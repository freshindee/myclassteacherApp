import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user.dart';
import 'master_data_service.dart';

class UserSessionService {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _studentDetailsKey = 'current_student_details';

  /// In-memory session when "Remember me" is unchecked (cleared when app process ends).
  static User? _temporaryUser;
  static Map<String, dynamic>? _temporaryStudentDetails;

  /// Saves user session. [rememberMe] true = persist across app restarts; false = keep in memory only (logout when app is closed).
  static Future<void> saveUserSession(
    User user, {
    Map<String, dynamic>? studentDetails,
    bool rememberMe = true,
  }) async {
    if (rememberMe) {
      _temporaryUser = null;
      _temporaryStudentDetails = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode({
        'userId': user.userId,
        'phoneNumber': user.phoneNumber,
        'password': user.password,
        'name': user.name,
        'birthday': user.birthday?.toIso8601String(),
        'district': user.district,
        'teacherId': user.teacherId,
      }));
      await prefs.setBool(_isLoggedInKey, true);
      if (studentDetails != null) {
        await prefs.setString(_studentDetailsKey, jsonEncode(studentDetails));
      } else {
        await prefs.remove(_studentDetailsKey);
      }
    } else {
      _temporaryUser = user;
      _temporaryStudentDetails = studentDetails;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_studentDetailsKey);
      await prefs.setBool(_isLoggedInKey, false);
    }
  }

  // Get current user session (from memory first, then from persisted storage)
  static Future<User?> getCurrentUser() async {
    if (_temporaryUser != null) return _temporaryUser;
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
        name: userMap['name'],
        birthday: userMap['birthday'] != null ? DateTime.parse(userMap['birthday']) : null,
        district: userMap['district'],
        teacherId: userMap['teacherId'],
      );
    } catch (e) {
      await clearUserSession();
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    if (_temporaryUser != null) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user session (memory + persisted)
  static Future<void> clearUserSession() async {
    _temporaryUser = null;
    _temporaryStudentDetails = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_studentDetailsKey);
    await prefs.setBool(_isLoggedInKey, false);
    await MasterDataService.clearMasterData();
  }

  // Get user ID
  static Future<String?> getUserId() async {
    final user = await getCurrentUser();
    return user?.userId;
  }

  /// School ID (for students) or Teacher ID (for teachers). Use when you need the current school/institute id.
  static Future<String?> getSchoolId() async {
    final user = await getCurrentUser();
    return user?.teacherId;
  }

  /// Saved student details after student login (school_id, student_id, full_name, grade, class, admission_no, etc.). Null if not a student or not logged in.
  static Future<Map<String, dynamic>?> getStudentDetails() async {
    if (_temporaryStudentDetails != null) return _temporaryStudentDetails;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_studentDetailsKey);
    if (json == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Merges [patch] into the current student details (in-memory or SharedPreferences).
  static Future<void> mergeStudentDetails(Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    final user = await getCurrentUser();
    if (user == null) return;

    final current = await getStudentDetails();
    final merged = Map<String, dynamic>.from(current ?? {})..addAll(patch);

    if (_temporaryUser != null) {
      _temporaryStudentDetails = merged;
      return;
    }

    await saveUserSession(user, studentDetails: merged, rememberMe: true);
  }
} 