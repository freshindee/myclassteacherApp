import '../../domain/entities/teacher.dart';

class TeacherModel {
  final String id;
  final String name;
  final String subject;
  final String grade;
  final String image;
  final String phone;
  final String displayId;
  final String qualification;
  final String specialization;

  TeacherModel({
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

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    // Handle teacherName field - use it if name is not available
    final name = json['name'] as String? ??
                 json['teacherName'] as String? ??
                 '';
    final qualification = (json['qualification'] ?? json['qualification_name'])?.toString().trim() ?? '';
    final specialization = (json['specialization'] ?? json['specialization_name'])?.toString().trim() ?? '';

    return TeacherModel(
      id: json['id']?.toString() ?? '',
      name: name,
      subject: json['subject'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      image: json['image'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      displayId: json['display_id'] as String? ?? json['displayId'] as String? ?? '',
      qualification: qualification,
      specialization: specialization,
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
      displayId: displayId,
      qualification: qualification,
      specialization: specialization,
    );
  }
} 