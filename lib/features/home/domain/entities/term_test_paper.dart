import 'package:equatable/equatable.dart';

class TermTestPaper extends Equatable {
  final String id;
  final String title;
  final String description;
  final String grade;
  final String subject;
  final String pdfUrl;
  final int term;

  const TermTestPaper({
    required this.id,
    required this.title,
    required this.description,
    required this.grade,
    required this.subject,
    required this.pdfUrl,
    required this.term,
  });

  @override
  List<Object?> get props => [id, title, description, grade, subject, pdfUrl, term];
} 