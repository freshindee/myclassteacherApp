import '../../domain/entities/exam_chapter.dart';

class ExamChapterModel {
  final int id;
  final String name;
  final String? description;
  final int subjectId;

  ExamChapterModel({
    required this.id,
    required this.name,
    this.description,
    required this.subjectId,
  });

  factory ExamChapterModel.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase and snake_case field names
    // API returns: chapter_id, chapter_title, subject_id, chapter_number
    // Based on database table structure
    
    // Parse chapter_id (primary key)
    int? id;
    if (json['chapter_id'] != null) {
      id = json['chapter_id'] is int 
          ? json['chapter_id'] as int
          : int.tryParse(json['chapter_id'].toString());
    } else if (json['id'] != null) {
      id = json['id'] is int 
          ? json['id'] as int
          : int.tryParse(json['id'].toString());
    }
    
    // Parse chapter_title (name)
    String name = json['chapter_title'] as String? ?? 
                  json['name'] as String? ?? 
                  json['title'] as String? ?? 
                  '';
    
    // Parse description (optional)
    String? description = json['description'] as String?;
    
    // Parse subject_id
    int? subjectId;
    if (json['subject_id'] != null) {
      subjectId = json['subject_id'] is int 
          ? json['subject_id'] as int
          : int.tryParse(json['subject_id'].toString());
    } else if (json['subjectId'] != null) {
      subjectId = json['subjectId'] is int 
          ? json['subjectId'] as int
          : int.tryParse(json['subjectId'].toString());
    }
    
    return ExamChapterModel(
      id: id ?? 0,
      name: name,
      description: description,
      subjectId: subjectId ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subjectId': subjectId,
    };
  }

  ExamChapter toEntity() {
    return ExamChapter(
      id: id,
      name: name,
      description: description,
      subjectId: subjectId,
    );
  }
}
