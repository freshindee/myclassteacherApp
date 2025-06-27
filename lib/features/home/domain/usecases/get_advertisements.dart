import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/video.dart';
import '../repositories/advertisement_repository.dart';

class GetAdvertisements implements UseCase<List<Video>, NoParams> {
  final AdvertisementRepository repository;

  GetAdvertisements(this.repository);

  @override
  Future<Either<Failure, List<Video>>> call(NoParams params) async {
    return await repository.getAdvertisements();
  }
} 