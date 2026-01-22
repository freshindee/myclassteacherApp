import 'package:equatable/equatable.dart';

class ExamQuestion extends Equatable {
  final int id;
  final int paperId;
  final int subjectId;
  final int chapterId;
  final String questionText;
  final String? imageUrl;
  // Text options (for type 1)
  final String? optionAText;
  final String? optionBText;
  final String? optionCText;
  final String? optionDText;
  // Image options (for type 2)
  final String? optionAImage;
  final String? optionBImage;
  final String? optionCImage;
  final String? optionDImage;
  final String correctOption;
  final String? explanation;
  final String type;
  final double marks; // Marks for this question (default 1.0 if not specified)

  const ExamQuestion({
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

  // Helper method to check if question uses text options
  bool get hasTextOptions => 
      optionAText != null && optionAText!.isNotEmpty ||
      optionBText != null && optionBText!.isNotEmpty ||
      optionCText != null && optionCText!.isNotEmpty ||
      optionDText != null && optionDText!.isNotEmpty;

  // Helper method to check if question uses image options
  bool get hasImageOptions =>
      optionAImage != null && optionAImage!.isNotEmpty ||
      optionBImage != null && optionBImage!.isNotEmpty ||
      optionCImage != null && optionCImage!.isNotEmpty ||
      optionDImage != null && optionDImage!.isNotEmpty;

  // Legacy getters for backward compatibility
  String get optionA => optionAText ?? '';
  String get optionB => optionBText ?? '';
  String get optionC => optionCText ?? '';
  String get optionD => optionDText ?? '';

  @override
  List<Object?> get props => [
        id,
        paperId,
        subjectId,
        chapterId,
        questionText,
        imageUrl,
        optionAText,
        optionBText,
        optionCText,
        optionDText,
        optionAImage,
        optionBImage,
        optionCImage,
        optionDImage,
        correctOption,
        explanation,
        type,
        marks,
      ];
}
