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
    return await repository.getFreeVideosByGrade(params.schoolId, params.grade);
  }
}

class GetFreeVideosByGradeParams {
  final String schoolId;
  final String grade;
  
  GetFreeVideosByGradeParams({required this.schoolId, required this.grade});
} 