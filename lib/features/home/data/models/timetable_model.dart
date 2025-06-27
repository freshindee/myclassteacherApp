import 'package:equatable/equatable.dart';
import '../../domain/entities/timetable.dart';

class TimetableModel extends Equatable {
  final String id;
  final String grade;
  final String subject;
  final String day;
  final String time;
  final String? teacher;
  final String? room;
  final String? description;

  const TimetableModel({
    required this.id,
    required this.grade,
    required this.subject,
    required this.day,
    required this.time,
    this.teacher,
    this.room,
    this.description,
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
      ];

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      day: json['day'] as String? ?? '',
      time: json['time'] as String? ?? '',
      teacher: json['teacher'] as String?,
      room: json['room'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'subject': subject,
      'day': day,
      'time': time,
      'teacher': teacher,
      'room': room,
      'description': description,
    };
  }

  Timetable toEntity() {
    return Timetable(
      id: id,
      grade: grade,
      subject: subject,
      day: day,
      time: time,
      teacher: teacher,
      room: room,
      description: description,
    );
  }
} 