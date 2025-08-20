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
    print('🎬   - teacherId: ${params.teacherId}');
    print('🎬   - grade: ${params.grade}');
    print('🎬   - subject: ${params.subject}');
    print('🎬   - month: ${params.month}');
    print('🎬   - year: ${params.year}');
    
    return await repository.getVideos(
      userId: params.userId,
      teacherId: params.teacherId,
      grade: params.grade,
      subject: params.subject,
      month: params.month,
      year: params.year,
    );
  }
}

class GetVideosParams extends Equatable {
  final String? userId;
  final String? teacherId;
  final String? grade;
  final String? subject;
  final int? month;
  final int? year;

  const GetVideosParams({
    this.userId,
    this.teacherId,
    this.grade,
    this.subject,
    this.month,
    this.year,
  });

  @override
  List<Object?> get props => [userId, teacherId, grade, subject, month, year];
} 