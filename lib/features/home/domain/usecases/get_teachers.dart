import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/teacher.dart';
import '../repositories/teacher_repository.dart';

class GetTeachers implements UseCase<List<Teacher>, String> {
  final TeacherRepository repository;
  GetTeachers(this.repository);
  @override
  Future<Either<Failure, List<Teacher>>> call(String teacherId) async {
    return await repository.getTeachers(teacherId);
  }
} 