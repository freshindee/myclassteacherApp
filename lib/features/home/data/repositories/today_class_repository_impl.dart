import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/today_class.dart';
import '../../domain/repositories/today_class_repository.dart';
import '../datasources/today_class_remote_data_source.dart';

class TodayClassRepositoryImpl implements TodayClassRepository {
  final TodayClassRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TodayClassRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TodayClass>>> getTodayClasses() async {
    if (await networkInfo.isConnected) {
      try {
        final models = await remoteDataSource.getTodayClasses();
        final entities = models.map((m) => m.toEntity()).toList();
        return Right(entities);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }
} 