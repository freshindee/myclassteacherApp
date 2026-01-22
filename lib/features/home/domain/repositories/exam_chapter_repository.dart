import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exam_chapter.dart';

abstract class ExamChapterRepository {
  Future<Either<Failure, List<ExamChapter>>> getExamChapters(int subjectId);
}
