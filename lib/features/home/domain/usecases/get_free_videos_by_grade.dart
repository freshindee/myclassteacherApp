import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class GetFreeVideosByGrade {
  final VideoRepository repository;
  GetFreeVideosByGrade(this.repository);
  Future<Either<Failure, List<Video>>> call(String grade) async {
    return await repository.getFreeVideosByGrade(grade);
  }
} 