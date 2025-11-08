import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/teacher_master_data.dart';
import '../../domain/repositories/teacher_master_data_repository.dart';
import '../datasources/teacher_master_data_remote_data_source.dart';

class TeacherMasterDataRepositoryImpl implements TeacherMasterDataRepository {
  final TeacherMasterDataRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TeacherMasterDataRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TeacherMasterData?>> getTeacherMasterData(String teacherId) async {
    if (await networkInfo.isConnected) {
      try {
        final masterDataModel = await remoteDataSource.getTeacherMasterData(teacherId);
        final masterData = masterDataModel?.toEntity();
        return Right(masterData);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}

