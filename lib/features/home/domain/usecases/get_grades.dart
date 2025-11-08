import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/grade.dart';
import '../repositories/grade_repository.dart';

class GetGrades implements UseCase<List<Grade>, String> {
  final GradeRepository repository;

  GetGrades(this.repository);

  @override
  Future<Either<Failure, List<Grade>>> call(String teacherId) async {
    return await repository.getGrades(teacherId);
  }
}

