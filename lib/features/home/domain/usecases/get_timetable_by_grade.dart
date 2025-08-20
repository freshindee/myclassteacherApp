import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/timetable.dart';
import '../repositories/timetable_repository.dart';

class GetTimetableByGrade implements UseCase<List<Timetable>, GetTimetableByGradeParams> {
  final TimetableRepository repository;
  GetTimetableByGrade(this.repository);
  
  @override
  Future<Either<Failure, List<Timetable>>> call(GetTimetableByGradeParams params) async {
    return await repository.getTimetableByGrade(params.teacherId, params.grade);
  }
}

class GetTimetableByGradeParams {
  final String teacherId;
  final String grade;
  
  GetTimetableByGradeParams({required this.teacherId, required this.grade});
} 