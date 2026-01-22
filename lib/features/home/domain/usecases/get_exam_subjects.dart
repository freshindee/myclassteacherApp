import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/exam_subject.dart';
import '../repositories/exam_subject_repository.dart';

class GetExamSubjects implements UseCase<List<ExamSubject>, NoParams> {
  final ExamSubjectRepository repository;

  GetExamSubjects(this.repository);

  @override
  Future<Either<Failure, List<ExamSubject>>> call(NoParams params) async {
    return await repository.getExamSubjects();
  }
}
