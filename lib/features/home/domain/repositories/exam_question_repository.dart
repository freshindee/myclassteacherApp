import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exam_question.dart';

abstract class ExamQuestionRepository {
  Future<Either<Failure, List<ExamQuestion>>> getExamQuestions(int paperId);
}
