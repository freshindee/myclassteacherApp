import 'package:equatable/equatable.dart';
import '../../domain/entities/timetable.dart';

class TimetableModel extends Equatable {
  final String id;
  final String grade;
  final String subject;
  final String day;
  final String time;
  final String? teacher;
  final int? teacherId;
  final String? room;
  final String? description;
  final int? index;
  final String? time2;
  final String? time3;
  final int? displayId;

  const TimetableModel({
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
      ];

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      day: json['day'] as String? ?? '',
      time: json['time'] as String? ?? '',
      teacher: json['teacher'] as String?,
      teacherId: json['teacher_id'] as int?,
      room: json['room'] as String?,
      description: json['description'] as String?,
      index: json['index'] is int ? json['index'] : int.tryParse(json['index']?.toString() ?? ''),
      time2: json['time2'] as String?,
      time3: json['time3'] as String?,
      displayId: json['display_id'] is int
          ? json['display_id']
          : int.tryParse(json['display_id']?.toString() ?? ''),
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
      'teacherId': teacherId,
      'room': room,
      'description': description,
      'index': index,
      'time2': time2,
      'time3': time3,
      'display_id': displayId,
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
      teacherId: teacherId,
      room: room,
      description: description,
      index: index,
      time2: time2,
      time3: time3,
      displayId: displayId,
    );
  }
} 