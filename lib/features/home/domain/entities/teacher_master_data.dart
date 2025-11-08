import 'package:equatable/equatable.dart';
import 'teacher.dart';

class TeacherMasterData extends Equatable {
  final String teacherId;
  final List<String> grades;
  final List<String> subjects;
  final Map<String, Map<String, int>> pricing; // Map<subject, Map<grade, price>>
  final List<Teacher> teachers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TeacherMasterData({
    required this.teacherId,
    required this.grades,
    required this.subjects,
    required this.pricing,
    required this.teachers,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [teacherId, grades, subjects, pricing, teachers, createdAt, updatedAt];
}

