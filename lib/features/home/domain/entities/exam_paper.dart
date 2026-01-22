import 'package:equatable/equatable.dart';

class ExamPaper extends Equatable {
  final int paperId;
  final String title;
  final int subjectId;
  final int term;
  final String type;
  final String stream;
  final int timeLimit;
  final int totalMarks;
  final int chapterId;

  const ExamPaper({
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

  @override
  List<Object?> get props => [
        paperId,
        title,
        subjectId,
        term,
        type,
        stream,
        timeLimit,
        totalMarks,
        chapterId,
      ];
}
