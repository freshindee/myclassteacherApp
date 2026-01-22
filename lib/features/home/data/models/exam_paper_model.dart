import '../../domain/entities/exam_paper.dart';

class ExamPaperModel {
  final int paperId;
  final String title;
  final int subjectId;
  final int term;
  final String type;
  final String stream;
  final int timeLimit;
  final int totalMarks;
  final int chapterId;

  ExamPaperModel({
    required this.paperId,
    required this.title,
    required this.subjectId,
    required this.term,
    required this.type,
    required this.stream,
    required this.timeLimit,
    required this.totalMarks,
    required this.chapterId,
  });

  factory ExamPaperModel.fromJson(Map<String, dynamic> json) {
    // Parse paper_id
    int? paperId;
    if (json['paper_id'] != null) {
      paperId = json['paper_id'] is int 
          ? json['paper_id'] as int
          : int.tryParse(json['paper_id'].toString());
    } else if (json['paperId'] != null) {
      paperId = json['paperId'] is int 
          ? json['paperId'] as int
          : int.tryParse(json['paperId'].toString());
    }
    
    // Parse title
    String title = json['title'] as String? ?? '';
    
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
    
    // Parse term
    int? term;
    if (json['term'] != null) {
      term = json['term'] is int 
          ? json['term'] as int
          : int.tryParse(json['term'].toString());
    }
    
    // Parse type
    String type = json['type'] as String? ?? 'text';
    
    // Parse stream
    String stream = json['stream'] as String? ?? '';
    
    // Parse time_limit
    int? timeLimit;
    if (json['time_limit'] != null) {
      timeLimit = json['time_limit'] is int 
          ? json['time_limit'] as int
          : int.tryParse(json['time_limit'].toString());
    } else if (json['timeLimit'] != null) {
      timeLimit = json['timeLimit'] is int 
          ? json['timeLimit'] as int
          : int.tryParse(json['timeLimit'].toString());
    }
    
    // Parse total_marks
    int? totalMarks;
    if (json['total_marks'] != null) {
      totalMarks = json['total_marks'] is int 
          ? json['total_marks'] as int
          : int.tryParse(json['total_marks'].toString());
    } else if (json['totalMarks'] != null) {
      totalMarks = json['totalMarks'] is int 
          ? json['totalMarks'] as int
          : int.tryParse(json['totalMarks'].toString());
    }
    
    // Parse chapter_id
    int? chapterId;
    if (json['chapter_id'] != null) {
      chapterId = json['chapter_id'] is int 
          ? json['chapter_id'] as int
          : int.tryParse(json['chapter_id'].toString());
    } else if (json['chapterId'] != null) {
      chapterId = json['chapterId'] is int 
          ? json['chapterId'] as int
          : int.tryParse(json['chapterId'].toString());
    }
    
    return ExamPaperModel(
      paperId: paperId ?? 0,
      title: title,
      subjectId: subjectId ?? 0,
      term: term ?? 1,
      type: type,
      stream: stream,
      timeLimit: timeLimit ?? 60,
      totalMarks: totalMarks ?? 100,
      chapterId: chapterId ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paper_id': paperId,
      'title': title,
      'subject_id': subjectId,
      'term': term,
      'type': type,
      'stream': stream,
      'time_limit': timeLimit,
      'total_marks': totalMarks,
      'chapter_id': chapterId,
    };
  }

  ExamPaper toEntity() {
    return ExamPaper(
      paperId: paperId,
      title: title,
      subjectId: subjectId,
      term: term,
      type: type,
      stream: stream,
      timeLimit: timeLimit,
      totalMarks: totalMarks,
      chapterId: chapterId,
    );
  }
}
