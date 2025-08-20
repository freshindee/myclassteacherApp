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
  Future<Either<Failure, List<TodayClass>>> getTodayClasses(String teacherId) async {
    print('📚 [REPOSITORY] TodayClassRepository.getTodayClasses called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final classModels = await remoteDataSource.getTodayClasses(teacherId);
        print('📚 [REPOSITORY] Successfully fetched ${classModels.length} today class models from remote data source');
        
        final classes = classModels.map((model) => TodayClass(
          grade: model.grade,
          subject: model.subject,
          teacher: model.teacher,
          teacherId: model.teacherId,
          time: model.time,
          joinUrl: model.joinUrl,
        )).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${classes.length} today class models to entities');
        return Right(classes);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch today classes: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 