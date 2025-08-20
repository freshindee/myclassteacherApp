import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetFreeVideos implements UseCase<List<Video>, String> {
  final VideoRepository repository;
  GetFreeVideos(this.repository);
  @override
  Future<Either<Failure, List<Video>>> call(String teacherId) async {
    return await repository.getFreeVideos(teacherId);
  }
} 