import '../../domain/entities/note.dart';

class NoteModel extends Note {
  const NoteModel({
    required super.id,
    required super.grade,
    required super.title,
    required super.description,
    required super.pdfUrl,
    super.month,
  });

  static int? _parseMonth(Map<String, dynamic> json) {
    final v = json['month'] ?? json['Month'];
    if (v == null) return null;
    if (v is int) return v >= 1 && v <= 12 ? v : null;
    final n = int.tryParse(v.toString());
    if (n == null || n < 1 || n > 12) return null;
    return n;
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String? ?? json['pdf_url'] as String? ?? '',
      month: _parseMonth(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'title': title,
      'description': description,
      'url': pdfUrl,
    };
  }
} 