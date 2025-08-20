import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/term_test_paper.dart';

abstract class TermTestPaperRepository {
  Future<Either<Failure, List<TermTestPaper>>> getTermTestPapers({required String teacherId, String? grade, String? subject, int? term});
} 