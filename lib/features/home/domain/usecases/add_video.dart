import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/video.dart';
import '../repositories/video_repository.dart';

class AddVideoParams {
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumb;
  final String? grade;
  final String? subject;
  final String accessLevel;

  AddVideoParams({
    required this.title,
    required this.description,
    required this.youtubeUrl,
    required this.thumb,
    this.grade,
    this.subject,
    this.accessLevel = 'free',
  });
}

class AddVideo implements UseCase<Video, AddVideoParams> {
  final VideoRepository repository;

  AddVideo(this.repository);

  @override
  Future<Either<Failure, Video>> call(AddVideoParams params) async {
    return await repository.addVideo(params);
  }
} 