import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/teacher_master_data.dart';
import '../repositories/teacher_master_data_repository.dart';

class GetTeacherMasterData implements UseCase<TeacherMasterData?, String> {
  final TeacherMasterDataRepository repository;

  GetTeacherMasterData(this.repository);

  @override
  Future<Either<Failure, TeacherMasterData?>> call(String teacherId) async {
    return await repository.getTeacherMasterData(teacherId);
  }
}

