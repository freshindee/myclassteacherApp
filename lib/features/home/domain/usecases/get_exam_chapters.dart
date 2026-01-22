import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/exam_chapter.dart';
import '../repositories/exam_chapter_repository.dart';

class GetExamChapters implements UseCase<List<ExamChapter>, int> {
  final ExamChapterRepository repository;

  GetExamChapters(this.repository);

  @override
  Future<Either<Failure, List<ExamChapter>>> call(int subjectId) async {
    return await repository.getExamChapters(subjectId);
  }
}
