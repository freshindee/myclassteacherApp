import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/today_class.dart';
import '../repositories/today_class_repository.dart';

class GetTodayClasses implements UseCase<List<TodayClass>, String> {
  final TodayClassRepository repository;
  GetTodayClasses(this.repository);
  @override
  Future<Either<Failure, List<TodayClass>>> call(String teacherId) async {
    return await repository.getTodayClasses(teacherId);
  }
} 