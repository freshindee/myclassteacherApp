import '../entities/term_test_paper.dart';
import '../repositories/term_test_paper_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';

class GetTermTestPapers implements UseCase<List<TermTestPaper>, GetTermTestPapersParams> {
  final TermTestPaperRepository repository;

  GetTermTestPapers(this.repository);

  @override
  Future<Either<Failure, List<TermTestPaper>>> call(GetTermTestPapersParams params) async {
    try {
      final result = await repository.getTermTestPapers(
        teacherId: params.teacherId, 
        grade: params.grade, 
        subject: params.subject, 
        term: params.term
      );
      return result;
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class GetTermTestPapersParams {
  final String teacherId;
  final String? grade;
  final String? subject;
  final int? term;
  
  GetTermTestPapersParams({
    required this.teacherId, 
    this.grade, 
    this.subject, 
    this.term
  });
} 