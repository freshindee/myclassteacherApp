import '../../domain/entities/subject.dart';

class SubjectModel {
  final String id;
  final String subject;
  final String teacherId;

  SubjectModel({
    required this.id,
    required this.subject,
    required this.teacherId,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      teacherId: json['teacherId'] as String? ?? '',
    );
  }

  Subject toEntity() {
    return Subject(
      id: id,
      subject: subject,
      teacherId: teacherId,
    );
  }
}

