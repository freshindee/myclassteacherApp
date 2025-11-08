import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/teacher_master_data.dart';

abstract class TeacherMasterDataRepository {
  Future<Either<Failure, TeacherMasterData?>> getTeacherMasterData(String teacherId);
}

