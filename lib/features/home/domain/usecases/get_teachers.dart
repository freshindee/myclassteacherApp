import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/teacher.dart';
import '../repositories/teacher_repository.dart';

class GetTeachers implements UseCase<List<Teacher>, NoParams> {
  final TeacherRepository repository;
  GetTeachers(this.repository);
  @override
  Future<Either<Failure, List<Teacher>>> call(NoParams params) async {
    return await repository.getTeachers();
  }
} 