import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/domain/entities/user.dart';
import '../../features/home/domain/entities/subject.dart';
import '../../features/home/domain/entities/grade.dart';
import '../../features/home/domain/entities/teacher.dart';
import '../../features/home/domain/entities/teacher_master_data.dart';

class MasterDataService {
  static const String _userKey = 'master_user';
  static const String _subjectsKey = 'master_subjects';
  static const String _gradesKey = 'master_grades';
  static const String _teachersKey = 'master_teachers';
  static const String _teacherMasterDataKey = 'teacher_master_data';

  // Save user details
  static Future<void> saveUserDetails(User user) async {
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
  }

  // Get user details
  static Future<User?> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) {
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
      return null;
    }
  }

  // Save subjects
  static Future<void> saveSubjects(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = jsonEncode(
      subjects.map((s) => {
        'id': s.id,
        'subject': s.subject,
        'teacherId': s.teacherId,
      }).toList(),
    );
    await prefs.setString(_subjectsKey, subjectsJson);
  }

  // Get subjects
  static Future<List<Subject>> getSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final subjectsJson = prefs.getString(_subjectsKey);
    if (subjectsJson == null) {
      return [];
    }
    try {
      final List<dynamic> subjectsList = jsonDecode(subjectsJson);
      return subjectsList.map((json) => Subject(
        id: json['id'] as String,
        subject: json['subject'] as String,
        teacherId: json['teacherId'] as String,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Save grades
  static Future<void> saveGrades(List<Grade> grades) async {
    final prefs = await SharedPreferences.getInstance();
    final gradesJson = jsonEncode(
      grades.map((g) => {
        'id': g.id,
        'name': g.name,
        'teacherId': g.teacherId,
      }).toList(),
    );
    await prefs.setString(_gradesKey, gradesJson);
  }

  // Get grades
  static Future<List<Grade>> getGrades() async {
    final prefs = await SharedPreferences.getInstance();
    final gradesJson = prefs.getString(_gradesKey);
    if (gradesJson == null) {
      return [];
    }
    try {
      final List<dynamic> gradesList = jsonDecode(gradesJson);
      return gradesList.map((json) => Grade(
        id: json['id'] as String,
        name: json['name'] as String,
        teacherId: json['teacherId'] as String,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Save teachers
  static Future<void> saveTeachers(List<Teacher> teachers) async {
    final prefs = await SharedPreferences.getInstance();
    final teachersJson = jsonEncode(
      teachers.map((t) => {
        'id': t.id,
        'name': t.name,
        'subject': t.subject,
        'grade': t.grade,
        'image': t.image,
        'phone': t.phone,
        'displayId': t.displayId,
      }).toList(),
    );
    await prefs.setString(_teachersKey, teachersJson);
  }

  // Get teachers
  static Future<List<Teacher>> getTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final teachersJson = prefs.getString(_teachersKey);
    if (teachersJson == null) {
      return [];
    }
    try {
      final List<dynamic> teachersList = jsonDecode(teachersJson);
      return teachersList.map((json) => Teacher(
        id: json['id'] as String,
        name: json['name'] as String,
        subject: json['subject'] as String,
        grade: json['grade'] as String,
        image: json['image'] as String,
        phone: json['phone'] as String? ?? '',
        displayId: json['displayId'] as String? ?? '',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  // Save teacher master data
  static Future<void> saveTeacherMasterData(TeacherMasterData masterData) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString(_teacherMasterDataKey, jsonEncode({
      'teacherId': masterData.teacherId,
      'grades': masterData.grades,
      'subjects': masterData.subjects,
      'pricing': masterData.pricing,
      'teachers': masterData.teachers.map((t) => {
        'id': t.id,
        'name': t.name,
        'subject': t.subject,
        'grade': t.grade,
        'image': t.image,
        'phone': t.phone,
        'displayId': t.displayId,
      }).toList(),
      'bankDetails': masterData.bankDetails,
      'sliderImages': masterData.sliderImages,
      'createdAt': masterData.createdAt?.toIso8601String(),
      'updatedAt': masterData.updatedAt?.toIso8601String(),
      'cachedAt': now.toIso8601String(), // Add cache timestamp
    }));
    
    // Also convert and save as Grade and Subject entities for backward compatibility
    final grades = masterData.grades.map((gradeName) => Grade(
      id: gradeName,
      name: gradeName,
      teacherId: masterData.teacherId,
    )).toList();
    await saveGrades(grades);
    
    final subjects = masterData.subjects.map((subjectName) => Subject(
      id: subjectName,
      subject: subjectName,
      teacherId: masterData.teacherId,
    )).toList();
    await saveSubjects(subjects);
    
    // Save teachers separately for backward compatibility
    await saveTeachers(masterData.teachers);
  }

  // Get teacher master data
  static Future<TeacherMasterData?> getTeacherMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    final masterDataJson = prefs.getString(_teacherMasterDataKey);
    if (masterDataJson == null) {
      print('📦 [DEBUG] MasterDataService - No master data found in SharedPreferences');
      return null;
    }
    try {
      print('📦 [DEBUG] MasterDataService - Found master data in SharedPreferences');
      final masterDataMap = jsonDecode(masterDataJson) as Map<String, dynamic>;
      
      // Check cache timestamp
      DateTime? cachedAt;
      if (masterDataMap['cachedAt'] != null) {
        cachedAt = DateTime.parse(masterDataMap['cachedAt']);
        final now = DateTime.now();
        final difference = now.difference(cachedAt);
        
        print('📦 [DEBUG] MasterDataService - Cache age: ${difference.inHours} hours ${difference.inMinutes % 60} minutes');
        
        // If cache is older than 2 hours, return null to trigger refresh
        if (difference.inHours >= 2) {
          print('📦 [DEBUG] MasterDataService - Cache is older than 2 hours, needs refresh');
          return null;
        }
      } else {
        // If no cachedAt timestamp exists, treat as old cache and refresh
        print('📦 [DEBUG] MasterDataService - No cachedAt timestamp, needs refresh');
        return null;
      }
      
      final teacherId = masterDataMap['teacherId'] as String;
      final grades = List<String>.from(masterDataMap['grades'] as List);
      final subjects = List<String>.from(masterDataMap['subjects'] as List);
      
      // Parse teachers array
      final teachersList = masterDataMap['teachers'] as List<dynamic>? ?? [];
      final List<Teacher> teachers = teachersList.map((json) => Teacher(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        grade: json['grade'] as String? ?? '',
        image: json['image'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        displayId: json['displayId'] as String? ?? '',
      )).toList();
      
      // Parse bankDetails array
      final bankDetailsList = masterDataMap['bankDetails'] as List<dynamic>? ?? [];
      final bankDetails = bankDetailsList.map((e) => e.toString()).toList();
      
      // Parse sliderImages array
      final sliderImagesList = masterDataMap['sliderImages'] as List<dynamic>? ?? [];
      final sliderImages = sliderImagesList.map((e) => e.toString()).toList();
      
      print('📦 [DEBUG] MasterDataService - teacherId: $teacherId');
      print('📦 [DEBUG] MasterDataService - grades count: ${grades.length}');
      print('📦 [DEBUG] MasterDataService - grades: $grades');
      print('📦 [DEBUG] MasterDataService - subjects count: ${subjects.length}');
      print('📦 [DEBUG] MasterDataService - subjects: $subjects');
      print('📦 [DEBUG] MasterDataService - teachers count: ${teachers.length}');
      print('📦 [DEBUG] MasterDataService - bankDetails count: ${bankDetails.length}');
      print('📦 [DEBUG] MasterDataService - sliderImages count: ${sliderImages.length}');
      
      return TeacherMasterData(
        teacherId: teacherId,
        grades: grades,
        subjects: subjects,
        pricing: Map<String, Map<String, int>>.from(
          (masterDataMap['pricing'] as Map).map(
            (key, value) => MapEntry(
              key as String,
              Map<String, int>.from((value as Map).map(
                (k, v) => MapEntry(k.toString(), v is int ? v : (v as num).toInt()),
              )),
            ),
          ),
        ),
        teachers: teachers,
        bankDetails: bankDetails,
        sliderImages: sliderImages,
        createdAt: masterDataMap['createdAt'] != null 
            ? DateTime.parse(masterDataMap['createdAt']) 
            : null,
        updatedAt: masterDataMap['updatedAt'] != null 
            ? DateTime.parse(masterDataMap['updatedAt']) 
            : null,
      );
    } catch (e) {
      print('❌ [DEBUG] MasterDataService - Error parsing master data: $e');
      return null;
    }
  }

  // Get pricing for a specific subject and grade
  static Future<int?> getPricing(String subject, String grade) async {
    final masterData = await getTeacherMasterData();
    if (masterData == null) {
      return null;
    }
    return masterData.pricing[subject]?[grade];
  }

  // Check if master data needs refresh
  static Future<bool> shouldRefreshMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    final masterDataJson = prefs.getString(_teacherMasterDataKey);
    if (masterDataJson == null) {
      return true; // No cache, needs refresh
    }
    
    try {
      final masterDataMap = jsonDecode(masterDataJson) as Map<String, dynamic>;
      if (masterDataMap['cachedAt'] == null) {
        return true; // No timestamp, needs refresh
      }
      
      final cachedAt = DateTime.parse(masterDataMap['cachedAt']);
      final now = DateTime.now();
      final difference = now.difference(cachedAt);
      
      return difference.inHours >= 2; // Refresh if older than 2 hours
    } catch (e) {
      print('❌ [DEBUG] MasterDataService - Error checking cache age: $e');
      return true; // Error parsing, needs refresh
    }
  }

  // Clear all master data
  static Future<void> clearMasterData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_subjectsKey);
    await prefs.remove(_gradesKey);
    await prefs.remove(_teachersKey);
    await prefs.remove(_teacherMasterDataKey);
  }
}

