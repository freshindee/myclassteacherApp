import 'package:equatable/equatable.dart';

class ExamChapter extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int subjectId;

  const ExamChapter({
    required this.id,
    required this.name,
    this.description,
    required this.subjectId,
  });

  @override
  List<Object?> get props => [id, name, description, subjectId];
}
