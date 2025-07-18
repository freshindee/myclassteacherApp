import 'package:equatable/equatable.dart';

class TodayClass extends Equatable {
  final String grade;
  final String subject;
  final String teacher;
  final int teacherId;
  final String time;
  final String joinUrl;

  const TodayClass({
    required this.grade,
    required this.subject,
    required this.teacher,
    required this.teacherId,
    required this.time,
    required this.joinUrl
  });

  @override
  List<Object?> get props => [grade, subject, teacher,teacherId, time, joinUrl];
} 