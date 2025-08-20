import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../repositories/timetable_repository.dart';

class GetAvailableGrades implements UseCase<List<String>, String> {
  final TimetableRepository repository;
  GetAvailableGrades(this.repository);
  
  @override
  Future<Either<Failure, List<String>>> call(String teacherId) async {
    return await repository.getAvailableGrades(teacherId);
  }
} 