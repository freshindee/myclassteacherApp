import '../entities/term_test_paper.dart';

abstract class TermTestPaperRepository {
  Future<List<TermTestPaper>> getTermTestPapers({String? grade, String? subject, int? term});
} 