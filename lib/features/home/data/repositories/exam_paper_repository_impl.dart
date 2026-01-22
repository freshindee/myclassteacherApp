import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/exam_paper_remote_data_source.dart';
import '../models/exam_paper_model.dart';
import '../../domain/entities/exam_paper.dart';
import '../../domain/repositories/exam_paper_repository.dart';

class ExamPaperRepositoryImpl implements ExamPaperRepository {
  final ExamPaperRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExamPaperRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExamPaper>>> getExamPapers({
    required String grade,
    required int subjectId,
    int? chapterId,
  }) async {
    print('📚 [REPOSITORY] ExamPaperRepository.getExamPapers called');
    print('📚 [REPOSITORY] - grade: $grade, subjectId: $subjectId, chapterId: $chapterId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final paperModels = await remoteDataSource.getExamPapers(
          grade: grade,
          subjectId: subjectId,
          chapterId: chapterId,
        );
        print('📚 [REPOSITORY] Successfully fetched ${paperModels.length} exam paper models from remote data source');
        
        final papers = paperModels.map((model) => model.toEntity()).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${papers.length} exam paper models to entities');
        return Right(papers);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch exam papers: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
}
