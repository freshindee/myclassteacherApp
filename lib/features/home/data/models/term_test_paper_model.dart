import 'package:equatable/equatable.dart';
import '../../domain/entities/term_test_paper.dart';

class TermTestPaperModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String grade;
  final String subject;
  final String pdfUrl;
  final int term;

  const TermTestPaperModel({
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

  factory TermTestPaperModel.fromJson(Map<String, dynamic> json) {
    return TermTestPaperModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? '',
      term: json['term'] is int ? json['term'] : int.tryParse(json['term']?.toString() ?? '') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'grade': grade,
      'subject': subject,
      'pdfUrl': pdfUrl,
      'term': term,
    };
  }

  TermTestPaper toEntity() {
    return TermTestPaper(
      id: id,
      title: title,
      description: description,
      grade: grade,
      subject: subject,
      pdfUrl: pdfUrl,
      term: term,
    );
  }
} 