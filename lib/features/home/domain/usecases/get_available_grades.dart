import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../repositories/timetable_repository.dart';

class GetAvailableGrades implements UseCase<List<String>, NoParams> {
  final TimetableRepository repository;
  GetAvailableGrades(this.repository);
  
  @override
  Future<Either<Failure, List<String>>> call(NoParams params) async {
    return await repository.getAvailableGrades();
  }
} 