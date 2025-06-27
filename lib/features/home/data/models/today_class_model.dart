import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/today_class.dart';

class TodayClassModel {
  final String grade;
  final String subject;
  final String teacher;
  final String time;
  final String joinUrl;

  TodayClassModel({
    required this.grade,
    required this.subject,
    required this.teacher,
    required this.time,
    required this.joinUrl,
  });

  factory TodayClassModel.fromJson(Map<String, dynamic> json) {
    return TodayClassModel(
      grade: json['grade'] as String,
      subject: json['subject'] as String,
      teacher: json['teacher'] as String,
      time: json['time'] as String,
      joinUrl: json['joinUrl'] as String,
    );
  }

  TodayClass toEntity() {
    return TodayClass(
      grade: grade,
      subject: subject,
      teacher: teacher,
      time:time,
      joinUrl: joinUrl,
    );
  }
} 