import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';
import 'package:equatable/equatable.dart';

class GetVideos implements UseCase<List<Video>, GetVideosParams> {
  final VideoRepository repository;

  GetVideos(this.repository);

  @override
  Future<Either<Failure, List<Video>>> call(GetVideosParams params) async {
    print('🎬 GetVideos usecase called with parameters:');
    print('🎬   - userId: ${params.userId}');
    print('🎬   - schoolId: ${params.schoolId}');
    print('🎬   - grade: ${params.grade}');
    print('🎬   - subject: ${params.subject}');
    print('🎬   - month: ${params.month}');
    print('🎬   - year: ${params.year}');
    
    return await repository.getVideos(
      userId: params.userId,
      schoolId: params.schoolId,
      grade: params.grade,
      subject: params.subject,
      month: params.month,
      year: params.year,
      accessLevel: params.accessLevel,
    );
  }
}

class GetVideosParams extends Equatable {
  final String? userId;
  final String? schoolId;
  final String? grade;
  final String? subject;
  final int? month;
  final int? year;
  final String? accessLevel;

  const GetVideosParams({
    this.userId,
    this.schoolId,
    this.grade,
    this.subject,
    this.month,
    this.year,
    this.accessLevel,
  });

  @override
  List<Object?> get props => [userId, schoolId, grade, subject, month, year, accessLevel];
} 