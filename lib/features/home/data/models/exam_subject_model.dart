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
    final id = json['id'];
    final name = json['name'];
    return ExamSubjectModel(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: name?.toString() ?? '',
      description: json['description']?.toString() ?? '',
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
