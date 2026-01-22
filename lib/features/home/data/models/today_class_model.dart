import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/today_class.dart';

class TodayClassModel {
  final String grade;
  final String subject;
  final String teacher;
  final String teacherId;
  final String time;
  final String joinUrl;
  final String? zoomId;
  final String? password;
  final String? accessLevel;

  TodayClassModel({
    required this.grade,
    required this.subject,
    required this.teacher,
    required this.teacherId,
    required this.time,
    required this.joinUrl,
    this.zoomId,
    this.password,
    this.accessLevel,
  });

  factory TodayClassModel.fromJson(Map<String, dynamic> json) {
    // Print all keys to debug
    print('📚 [MODEL] TodayClassModel.fromJson - All keys: ${json.keys.toList()}');
    
    // Handle zoomId - always convert to String
    String? zoomId;
    if (json['zoomId'] != null) {
      // Explicitly convert to String, handling both String and int types
      final zoomIdValue = json['zoomId'];
      if (zoomIdValue is String) {
        zoomId = zoomIdValue;
      } else if (zoomIdValue is int || zoomIdValue is num) {
        zoomId = zoomIdValue.toString();
      } else {
        zoomId = zoomIdValue.toString();
      }
    }
    
    // Handle password - always convert to String
    String? password;
    if (json['password'] != null) {
      // Explicitly convert to String, handling both String and int types
      final passwordValue = json['password'];
      if (passwordValue is String) {
        password = passwordValue;
      } else if (passwordValue is int || passwordValue is num) {
        password = passwordValue.toString();
      } else {
        password = passwordValue.toString();
      }
    }
    
    print('📚 [MODEL] TodayClassModel.fromJson - zoomId: $zoomId (original type: ${json['zoomId']?.runtimeType}, final type: ${zoomId?.runtimeType}), password: ${password != null ? "***" : null} (original type: ${json['password']?.runtimeType}, final type: ${password?.runtimeType})');
    
    return TodayClassModel(
      grade: json['grade'] as String,
      subject: json['subject'] as String,
      teacher: json['teacher'] as String,
      teacherId: json['teacherId'] as String,
      time: json['time'] as String,
      joinUrl: json['joinUrl'] as String,
      zoomId: zoomId,
      password: password,
      accessLevel: json['accessLevel'] as String?,
    );
  }

  TodayClass toEntity() {
    return TodayClass(
      grade: grade,
      subject: subject,
      teacher: teacher,
      teacherId: teacherId,
      time: time,
      joinUrl: joinUrl,
      zoomId: zoomId,
      password: password,
      accessLevel: accessLevel,
    );
  }
} 