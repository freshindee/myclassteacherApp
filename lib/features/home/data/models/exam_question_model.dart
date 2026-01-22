import '../../domain/entities/exam_question.dart';

class ExamQuestionModel {
  final int id;
  final int paperId;
  final int subjectId;
  final int chapterId;
  final String questionText;
  final String? imageUrl;
  final String? optionAText;
  final String? optionBText;
  final String? optionCText;
  final String? optionDText;
  final String? optionAImage;
  final String? optionBImage;
  final String? optionCImage;
  final String? optionDImage;
  final String correctOption;
  final String? explanation;
  final String type;
  final double marks; // Marks for this question

  ExamQuestionModel({
    required this.id,
    required this.paperId,
    required this.subjectId,
    required this.chapterId,
    required this.questionText,
    this.imageUrl,
    this.optionAText,
    this.optionBText,
    this.optionCText,
    this.optionDText,
    this.optionAImage,
    this.optionBImage,
    this.optionCImage,
    this.optionDImage,
    required this.correctOption,
    this.explanation,
    required this.type,
    this.marks = 1.0, // Default 1 mark per question
  });

  factory ExamQuestionModel.fromJson(Map<String, dynamic> json) {
    // Parse id
    int? id;
    if (json['id'] != null) {
      id = json['id'] is int 
          ? json['id'] as int
          : int.tryParse(json['id'].toString());
    }
    
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
    
    // Parse question_text
    String questionText = json['question_text'] as String? ?? 
                          json['questionText'] as String? ?? 
                          '';
    
    // Parse image_url
    String? imageUrl = json['image_url'] as String? ?? 
                       json['imageUrl'] as String?;
    if (imageUrl != null && imageUrl.isEmpty) {
      imageUrl = null;
    }
    
    // Parse text options
    String? optionAText = json['option_a_text'] as String? ?? 
                          json['optionAText'] as String?;
    if (optionAText != null && optionAText.isEmpty) {
      optionAText = null;
    }
    
    String? optionBText = json['option_b_text'] as String? ?? 
                          json['optionBText'] as String?;
    if (optionBText != null && optionBText.isEmpty) {
      optionBText = null;
    }
    
    String? optionCText = json['option_c_text'] as String? ?? 
                          json['optionCText'] as String?;
    if (optionCText != null && optionCText.isEmpty) {
      optionCText = null;
    }
    
    String? optionDText = json['option_d_text'] as String? ?? 
                          json['optionDText'] as String?;
    if (optionDText != null && optionDText.isEmpty) {
      optionDText = null;
    }
    
    // Parse image options
    String? optionAImage = json['option_a_image'] as String? ?? 
                           json['optionAImage'] as String?;
    if (optionAImage != null && optionAImage.isEmpty) {
      optionAImage = null;
    }
    
    String? optionBImage = json['option_b_image'] as String? ?? 
                           json['optionBImage'] as String?;
    if (optionBImage != null && optionBImage.isEmpty) {
      optionBImage = null;
    }
    
    String? optionCImage = json['option_c_image'] as String? ?? 
                           json['optionCImage'] as String?;
    if (optionCImage != null && optionCImage.isEmpty) {
      optionCImage = null;
    }
    
    String? optionDImage = json['option_d_image'] as String? ?? 
                           json['optionDImage'] as String?;
    if (optionDImage != null && optionDImage.isEmpty) {
      optionDImage = null;
    }
    
    // Legacy support: if old format (option_a, option_b, etc.) exists, use as text
    if (optionAText == null) {
      optionAText = json['option_a'] as String? ?? 
                    json['optionA'] as String?;
      if (optionAText != null && optionAText.isEmpty) {
        optionAText = null;
      }
    }
    if (optionBText == null) {
      optionBText = json['option_b'] as String? ?? 
                    json['optionB'] as String?;
      if (optionBText != null && optionBText.isEmpty) {
        optionBText = null;
      }
    }
    if (optionCText == null) {
      optionCText = json['option_c'] as String? ?? 
                    json['optionC'] as String?;
      if (optionCText != null && optionCText.isEmpty) {
        optionCText = null;
      }
    }
    if (optionDText == null) {
      optionDText = json['option_d'] as String? ?? 
                    json['optionD'] as String?;
      if (optionDText != null && optionDText.isEmpty) {
        optionDText = null;
      }
    }
    
    // Parse correct_option
    String correctOption = json['correct_option'] as String? ?? 
                           json['correctOption'] as String? ?? 
                           '';
    
    // Parse explanation
    String? explanation = json['explanation'] as String?;
    if (explanation != null && explanation.isEmpty) {
      explanation = null;
    }
    
    // Parse type
    String type = json['type'] as String? ?? 'text';
    
    // Parse marks
    double marks = 1.0; // Default 1 mark per question
    if (json['marks'] != null) {
      if (json['marks'] is num) {
        marks = (json['marks'] as num).toDouble();
      } else if (json['marks'] is String) {
        marks = double.tryParse(json['marks']) ?? 1.0;
      }
    } else if (json['mark'] != null) {
      // Alternative field name
      if (json['mark'] is num) {
        marks = (json['mark'] as num).toDouble();
      } else if (json['mark'] is String) {
        marks = double.tryParse(json['mark']) ?? 1.0;
      }
    }
    
    return ExamQuestionModel(
      id: id ?? 0,
      paperId: paperId ?? 0,
      subjectId: subjectId ?? 0,
      chapterId: chapterId ?? 0,
      questionText: questionText,
      imageUrl: imageUrl,
      optionAText: optionAText,
      optionBText: optionBText,
      optionCText: optionCText,
      optionDText: optionDText,
      optionAImage: optionAImage,
      optionBImage: optionBImage,
      optionCImage: optionCImage,
      optionDImage: optionDImage,
      correctOption: correctOption,
      explanation: explanation,
      type: type,
      marks: marks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paper_id': paperId,
      'subject_id': subjectId,
      'chapter_id': chapterId,
      'question_text': questionText,
      'image_url': imageUrl,
      'option_a_text': optionAText,
      'option_b_text': optionBText,
      'option_c_text': optionCText,
      'option_d_text': optionDText,
      'option_a_image': optionAImage,
      'option_b_image': optionBImage,
      'option_c_image': optionCImage,
      'option_d_image': optionDImage,
      'correct_option': correctOption,
      'explanation': explanation,
      'type': type,
      'marks': marks,
    };
  }

  ExamQuestion toEntity() {
    return ExamQuestion(
      id: id,
      paperId: paperId,
      subjectId: subjectId,
      chapterId: chapterId,
      questionText: questionText,
      imageUrl: imageUrl,
      optionAText: optionAText,
      optionBText: optionBText,
      optionCText: optionCText,
      optionDText: optionDText,
      optionAImage: optionAImage,
      optionBImage: optionBImage,
      optionCImage: optionCImage,
      optionDImage: optionDImage,
      correctOption: correctOption,
      explanation: explanation,
      type: type,
      marks: marks,
    );
  }
}
