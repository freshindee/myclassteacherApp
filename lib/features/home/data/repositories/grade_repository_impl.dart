import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_remote_data_source.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GradeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Grade>>> getGrades(String teacherId) async {
    if (await networkInfo.isConnected) {
      try {
        final gradeModels = await remoteDataSource.getGrades(teacherId);
        final grades = gradeModels.map((model) => model.toEntity()).toList();
        return Right(grades);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(NetworkFailure('No internet connection'));
    }
  }
}

