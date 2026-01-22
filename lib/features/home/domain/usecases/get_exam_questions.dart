import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/exam_question.dart';
import '../repositories/exam_question_repository.dart';

class GetExamQuestions implements UseCase<List<ExamQuestion>, int> {
  final ExamQuestionRepository repository;

  GetExamQuestions(this.repository);

  @override
  Future<Either<Failure, List<ExamQuestion>>> call(int paperId) async {
    return await repository.getExamQuestions(paperId);
  }
}
