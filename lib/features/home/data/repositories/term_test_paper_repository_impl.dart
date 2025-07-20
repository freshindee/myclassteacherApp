import '../../domain/entities/term_test_paper.dart';
import '../../domain/repositories/term_test_paper_repository.dart';
import '../datasources/term_test_paper_remote_data_source.dart';

class TermTestPaperRepositoryImpl implements TermTestPaperRepository {
  final TermTestPaperRemoteDataSource remoteDataSource;

  TermTestPaperRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TermTestPaper>> getTermTestPapers({String? grade, String? subject, int? term}) async {
    final models = await remoteDataSource.getTermTestPapers(grade: grade, subject: subject, term: term);
    return models.map((m) => m.toEntity()).toList();
  }
} 