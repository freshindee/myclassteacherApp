import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';
import '../../../../core/usecases.dart';

class GetFreeVideosByGrade implements UseCase<List<Video>, GetFreeVideosByGradeParams> {
  final VideoRepository repository;
  GetFreeVideosByGrade(this.repository);
  
  @override
  Future<Either<Failure, List<Video>>> call(GetFreeVideosByGradeParams params) async {
    return await repository.getFreeVideosByGrade(params.teacherId, params.grade);
  }
}

class GetFreeVideosByGradeParams {
  final String teacherId;
  final String grade;
  
  GetFreeVideosByGradeParams({required this.teacherId, required this.grade});
} 