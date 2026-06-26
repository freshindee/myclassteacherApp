import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/advertisement_repository.dart';
import '../datasources/advertisement_remote_data_source.dart';

class AdvertisementRepositoryImpl implements AdvertisementRepository {
  final AdvertisementRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AdvertisementRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Video>>> getAdvertisements(String schoolId) async {
    print('📢 [REPOSITORY] AdvertisementRepository.getAdvertisements called with schoolId: $schoolId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📢 [REPOSITORY] Network connected, calling remote data source...');
        final advertisementModels = await remoteDataSource.getAdvertisements(schoolId);
        print('📢 [REPOSITORY] Successfully fetched ${advertisementModels.length} advertisement models from remote data source');
        
        final advertisements = advertisementModels
            .map((model) => model.toEntity())
            .toList();
        
        print('📢 [REPOSITORY] Successfully converted ${advertisements.length} advertisement models to entities');
        return Right(advertisements);
      } catch (e) {
        print('📢 [REPOSITORY ERROR] Failed to fetch advertisements: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📢 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 