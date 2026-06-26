import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../usecases/add_video.dart';

abstract class VideoRepository {
  Future<Either<Failure, List<Video>>> getVideos({
    String? userId,
    String? schoolId,
    String? grade,
    String? subject,
    int? month,
    int? year,
    String? accessLevel,
  });
  Future<Either<Failure, List<Video>>> getFreeVideos(String schoolId);
  Future<Either<Failure, List<Video>>> getFreeVideosByGrade(String schoolId, String grade);
  Future<Either<Failure, Video>> addVideo(AddVideoParams params);
} 