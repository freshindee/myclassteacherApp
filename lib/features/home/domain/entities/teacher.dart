import 'package:equatable/equatable.dart';

class Teacher extends Equatable {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String image;
  final String phone;
  final String displayId;
  final String qualification;
  final String specialization;

  const Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.image,
    this.phone = '',
    this.displayId = '',
    this.qualification = '',
    this.specialization = '',
  });

  @override
  List<Object?> get props => [id, name, subject, grade, image, phone, displayId, qualification, specialization];
} 