import 'package:equatable/equatable.dart';

class Note extends Equatable {
  final String id;
  final String grade;
  final String title;
  final String description;
  final String pdfUrl;

  const Note({
    required this.id,
    required this.grade,
    required this.title,
    required this.description,
    required this.pdfUrl,
  });

  @override
  List<Object> get props => [id, grade, title, description, pdfUrl];
} 