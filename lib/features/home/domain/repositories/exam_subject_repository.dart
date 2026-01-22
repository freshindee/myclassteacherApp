import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exam_subject.dart';

abstract class ExamSubjectRepository {
  Future<Either<Failure, List<ExamSubject>>> getExamSubjects();
}
