import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/exam_question_remote_data_source.dart';
import '../models/exam_question_model.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/repositories/exam_question_repository.dart';

class ExamQuestionRepositoryImpl implements ExamQuestionRepository {
  final ExamQuestionRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExamQuestionRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExamQuestion>>> getExamQuestions(int paperId) async {
    print('📚 [REPOSITORY] ExamQuestionRepository.getExamQuestions called with paperId: $paperId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final questionModels = await remoteDataSource.getExamQuestions(paperId);
        print('📚 [REPOSITORY] Successfully fetched ${questionModels.length} exam question models from remote data source');
        
        final questions = questionModels.map((model) => model.toEntity()).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${questions.length} exam question models to entities');
        return Right(questions);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch exam questions: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
}
