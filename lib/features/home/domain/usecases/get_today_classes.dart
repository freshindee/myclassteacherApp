import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/today_class.dart';
import '../repositories/today_class_repository.dart';

class GetTodayClasses implements UseCase<List<TodayClass>, GetTodayClassesParams> {
  final TodayClassRepository repository;
  GetTodayClasses(this.repository);
  @override
  Future<Either<Failure, List<TodayClass>>> call(GetTodayClassesParams params) async {
    return await repository.getTodayClasses(params.teacherId, grade: params.grade, subject: params.subject);
  }
}

class GetTodayClassesParams extends Equatable {
  final String teacherId;
  final String? grade;
  final String? subject;
  
  const GetTodayClassesParams({
    required this.teacherId,
    this.grade,
    this.subject,
  });

  @override
  List<Object?> get props => [teacherId, grade, subject];
}