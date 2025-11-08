import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class GetSubjects implements UseCase<List<Subject>, String> {
  final SubjectRepository repository;

  GetSubjects(this.repository);

  @override
  Future<Either<Failure, List<Subject>>> call(String teacherId) async {
    return await repository.getSubjects(teacherId);
  }
}

