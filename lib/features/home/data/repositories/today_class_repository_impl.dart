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
  Future<Either<Failure, List<TodayClass>>> getTodayClasses(String schoolId) async {
    print('📚 [REPOSITORY] TodayClassRepository.getTodayClasses called with schoolId: $schoolId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final classModels = await remoteDataSource.getTodayClasses(schoolId);
        print('📚 [REPOSITORY] Successfully fetched ${classModels.length} today class models from remote data source');
        
        // Debug: Print zoomId and password for each model
        for (var model in classModels) {
          print('📚 [REPOSITORY] Model - zoomId: ${model.zoomId}, password: ${model.password != null ? "***" : null}');
        }
        
        final classes = classModels.map((model) => model.toEntity()).toList();
        
        // Debug: Print zoomId and password for each entity
        for (var cls in classes) {
          print('📚 [REPOSITORY] Entity - zoomId: ${cls.zoomId}, password: ${cls.password != null ? "***" : null}');
        }
        
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