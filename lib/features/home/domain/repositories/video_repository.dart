import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../usecases/add_video.dart';

abstract class VideoRepository {
  Future<Either<Failure, List<Video>>> getVideos({
    String? userId,
    String? teacherId,
    String? grade,
    String? subject,
    int? month,
    int? year,
  });
  Future<Either<Failure, List<Video>>> getFreeVideos(String teacherId);
  Future<Either<Failure, List<Video>>> getFreeVideosByGrade(String teacherId, String grade);
  Future<Either<Failure, Video>> addVideo(AddVideoParams params);
} 