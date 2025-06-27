import '../../domain/entities/teacher.dart';

class TeacherModel {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String image;
  final String phone;

  TeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.image,
    required this.phone,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      image: json['image'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  Teacher toEntity() {
    return Teacher(
      id: id,
      name: name,
      subject: subject,
      grade: grade,
      image: image,
      phone: phone,
    );
  }
} 