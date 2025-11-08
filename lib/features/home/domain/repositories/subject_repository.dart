import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/subject.dart';

abstract class SubjectRepository {
  Future<Either<Failure, List<Subject>>> getSubjects(String teacherId);
}

