import 'package:equatable/equatable.dart';

class TodayClass extends Equatable {
  final String grade;
  final String subject;
  final String teacher;
  final String teacherId;
  final String time;
  final String joinUrl;
  final String? zoomId;
  final String? password;
  final String? accessLevel;

  const TodayClass({
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

  @override
  List<Object?> get props => [grade, subject, teacher, teacherId, time, joinUrl, zoomId, password, accessLevel];
} 