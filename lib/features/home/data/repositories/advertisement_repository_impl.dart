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
  Future<Either<Failure, List<Video>>> getAdvertisements() async {
    if (await networkInfo.isConnected) {
      try {
        final advertisementModels = await remoteDataSource.getAdvertisements();
        final advertisements = advertisementModels
            .map((model) => model.toEntity())
            .toList();
        return Right(advertisements);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }
} 