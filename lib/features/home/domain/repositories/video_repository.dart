import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../usecases/add_video.dart';

abstract class VideoRepository {
  Future<Either<Failure, List<Video>>> getVideos({
    String? userId,
    String? grade,
    String? subject,
    int? month,
    int? year,
  });
  Future<Either<Failure, List<Video>>> getFreeVideos();
  Future<Either<Failure, List<Video>>> getFreeVideosByGrade(String grade);
  Future<Either<Failure, Video>> addVideo(AddVideoParams params);
} 