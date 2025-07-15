import 'package:equatable/equatable.dart';

class Timetable extends Equatable {
  final String id;
  final String grade;
  final String subject;
  final String day;
  final String time;
  final String? teacher;
  final String? room;
  final String? description;
  final int? index;
  final String? time2;
  final String? time3;

  const Timetable({
    required this.id,
    required this.grade,
    required this.subject,
    required this.day,
    required this.time,
    this.teacher,
    this.room,
    this.description,
    this.index,
    this.time2,
    this.time3,
  });

  @override
  List<Object?> get props => [
        id,
        grade,
        subject,
        day,
        time,
        teacher,
        room,
        description,
        index,
        time2,
        time3,
      ];
} 