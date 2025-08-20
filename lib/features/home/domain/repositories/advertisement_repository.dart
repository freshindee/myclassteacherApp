import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';

abstract class AdvertisementRepository {
  Future<Either<Failure, List<Video>>> getAdvertisements(String teacherId);
} 