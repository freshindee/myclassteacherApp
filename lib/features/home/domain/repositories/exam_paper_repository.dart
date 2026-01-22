import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exam_paper.dart';

abstract class ExamPaperRepository {
  Future<Either<Failure, List<ExamPaper>>> getExamPapers({
    required String grade,
    required int subjectId,
    int? chapterId,
  });
}
