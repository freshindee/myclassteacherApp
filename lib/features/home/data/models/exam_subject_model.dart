import '../../domain/entities/exam_subject.dart';

class ExamSubjectModel {
  final int id;
  final String name;
  final String description;

  ExamSubjectModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ExamSubjectModel.fromJson(Map<String, dynamic> json) {
    return ExamSubjectModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  ExamSubject toEntity() {
    return ExamSubject(
      id: id,
      name: name,
      description: description,
    );
  }
}
