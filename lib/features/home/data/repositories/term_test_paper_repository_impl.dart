import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/term_test_paper.dart';
import '../../domain/repositories/term_test_paper_repository.dart';
import '../datasources/term_test_paper_remote_data_source.dart';

class TermTestPaperRepositoryImpl implements TermTestPaperRepository {
  final TermTestPaperRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TermTestPaperRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TermTestPaper>>> getTermTestPapers({
    required String teacherId,
    String? grade,
    String? subject,
    int? term,
  }) async {
    print('📄 [REPOSITORY] TermTestPaperRepository.getTermTestPapers called with:');
    print('📄   - teacherId: $teacherId');
    print('📄   - grade: $grade');
    print('📄   - subject: $subject');
    print('📄   - term: $term');
    
    if (await networkInfo.isConnected) {
      try {
        print('📄 [REPOSITORY] Network connected, calling remote data source...');
        final paperModels = await remoteDataSource.getTermTestPapers(
          teacherId: teacherId,
          grade: grade,
          subject: subject,
          term: term,
        );
        print('📄 [REPOSITORY] Successfully fetched ${paperModels.length} term test paper models from remote data source');
        
        final papers = paperModels.map((model) => TermTestPaper(
          id: model.id,
          title: model.title,
          description: model.description,
          pdfUrl: model.pdfUrl,
          grade: model.grade,
          subject: model.subject,
          term: model.term,
        )).toList();
        
        print('📄 [REPOSITORY] Successfully converted ${papers.length} term test paper models to entities');
        return Right(papers);
      } catch (e) {
        print('📄 [REPOSITORY ERROR] Failed to fetch term test papers: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📄 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 