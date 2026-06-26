import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/exam_paper.dart';
import '../repositories/exam_paper_repository.dart';

class GetExamPapersParams {
  final String grade;
  final int subjectId;
  final int? chapterId;
  /// When set, sent as subject_id to API (paper table uses string subject_id e.g. class_subject id).
  final String? subjectIdStr;

  GetExamPapersParams({
    required this.grade,
    required this.subjectId,
    this.chapterId,
    this.subjectIdStr,
  });
}

class GetExamPapers implements UseCase<List<ExamPaper>, GetExamPapersParams> {
  final ExamPaperRepository repository;

  GetExamPapers(this.repository);

  @override
  Future<Either<Failure, List<ExamPaper>>> call(GetExamPapersParams params) async {
    return await repository.getExamPapers(
      grade: params.grade,
      subjectId: params.subjectId,
      chapterId: params.chapterId,
      subjectIdStr: params.subjectIdStr,
    );
  }
}
