import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/exam_subject_remote_data_source.dart';
import '../models/exam_subject_model.dart';
import '../../domain/entities/exam_subject.dart';
import '../../domain/repositories/exam_subject_repository.dart';

class ExamSubjectRepositoryImpl implements ExamSubjectRepository {
  final ExamSubjectRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ExamSubjectRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ExamSubject>>> getExamSubjects() async {
    print('📚 [REPOSITORY] ExamSubjectRepository.getExamSubjects called');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final subjectModels = await remoteDataSource.getExamSubjects();
        print('📚 [REPOSITORY] Successfully fetched ${subjectModels.length} exam subject models from remote data source');
        
        final subjects = subjectModels.map((model) => model.toEntity()).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${subjects.length} exam subject models to entities');
        return Right(subjects);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch exam subjects: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
}
