import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/timetable.dart';
import '../repositories/timetable_repository.dart';

class GetTimetableByGrade implements UseCase<List<Timetable>, String> {
  final TimetableRepository repository;
  GetTimetableByGrade(this.repository);
  
  @override
  Future<Either<Failure, List<Timetable>>> call(String grade) async {
    return await repository.getTimetableByGrade(grade);
  }
} 