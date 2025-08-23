import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/slider_remote_data_source.dart';
import '../../domain/entities/slider_image.dart';
import '../../domain/repositories/slider_repository.dart';

class SliderRepositoryImpl implements SliderRepository {
  final SliderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SliderRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SliderImage>>> getSliderImages(String teacherId) async {
    if (await networkInfo.isConnected) {
      try {
        print('🖼️ [REPOSITORY] SliderRepository.getSliderImages called with teacherId: $teacherId');
        final sliderImageModels = await remoteDataSource.getSliderImages(teacherId);
        final sliderImages = sliderImageModels.map((model) => model.toEntity()).toList();
        print('🖼️ [REPOSITORY] Successfully retrieved ${sliderImages.length} slider images for teacherId: $teacherId');
        return Right(sliderImages);
      } catch (e) {
        print('🖼️ [REPOSITORY ERROR] Failed to get slider images: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('🖼️ [REPOSITORY ERROR] No internet connection');
      return const Left(ServerFailure('No internet connection'));
    }
  }
}
