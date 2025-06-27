import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/timetable.dart';

abstract class TimetableRepository {
  Future<Either<Failure, List<Timetable>>> getTimetableByGrade(String grade);
  Future<Either<Failure, List<String>>> getAvailableGrades();
} 