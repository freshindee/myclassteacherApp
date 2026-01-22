import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/exam_chapter_remote_data_source.dart';
import '../models/exam_chapter_model.dart';
import '../../domain/entities/exam_chapter.dart';
import '../../domain/repositories/exam_chapter_repository.dart';

class ExamChapterRepositoryImpl implements ExamChapterRepository {
  final ExamChapterRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExamChapterRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExamChapter>>> getExamChapters(int subjectId) async {
    print('📚 [REPOSITORY] ExamChapterRepository.getExamChapters called with subjectId: $subjectId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final chapterModels = await remoteDataSource.getExamChapters(subjectId);
        print('📚 [REPOSITORY] Successfully fetched ${chapterModels.length} exam chapter models from remote data source');
        
        final chapters = chapterModels.map((model) => model.toEntity()).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${chapters.length} exam chapter models to entities');
        return Right(chapters);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch exam chapters: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
}
