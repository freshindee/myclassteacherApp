import 'package:equatable/equatable.dart';

class Teacher extends Equatable {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String image;
  final String phone;

  const Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.image,
    required this.phone,
  });

  @override
  List<Object?> get props => [id, name, subject, grade, image, phone];
} 