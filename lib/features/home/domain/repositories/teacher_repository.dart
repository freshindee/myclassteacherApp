import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/teacher.dart';

abstract class TeacherRepository {
  Future<Either<Failure, List<Teacher>>> getTeachers(String teacherId);
} 