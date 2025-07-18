import 'package:equatable/equatable.dart';

class Timetable extends Equatable {
  final String id;
  final String grade;
  final String subject;
  final String day;
  final String time;
  final String? teacher;
  final int ?teacherId;
  final String? room;
  final String? description;
  final int? index;
  final String? time2;
  final String? time3;
  final int? displayId;

  const Timetable({
    required this.id,
    required this.grade,
    required this.subject,
    required this.day,
    required this.time,
    this.teacher,
    this.teacherId,
    this.room,
    this.description,
    this.index,
    this.time2,
    this.time3,
    this.displayId,
  });

  @override
  List<Object?> get props => [
        id,
        grade,
        subject,
        day,
        time,
        teacher,teacherId,
        room,
        description,
        index,
        time2,
        time3,
        displayId,
      ];
} 