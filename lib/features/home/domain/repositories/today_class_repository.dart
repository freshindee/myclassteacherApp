import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/today_class.dart';

abstract class TodayClassRepository {
  Future<Either<Failure, List<TodayClass>>> getTodayClasses();
} 