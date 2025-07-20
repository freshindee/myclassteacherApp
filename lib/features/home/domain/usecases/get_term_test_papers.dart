import '../entities/term_test_paper.dart';
import '../repositories/term_test_paper_repository.dart';

class GetTermTestPapers {
  final TermTestPaperRepository repository;

  GetTermTestPapers(this.repository);

  Future<List<TermTestPaper>> call({String? grade, String? subject, int? term}) {
    return repository.getTermTestPapers(grade: grade, subject: subject, term: term);
  }
} 