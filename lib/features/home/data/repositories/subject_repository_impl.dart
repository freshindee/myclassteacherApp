import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/subject_remote_data_source.dart';
import '../models/subject_model.dart';
import '../../domain/entities/subject.dart';
import '../../domain/repositories/subject_repository.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  final SubjectRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SubjectRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Subject>>> getSubjects(String teacherId) async {
    print('📚 [REPOSITORY] SubjectRepository.getSubjects called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📚 [REPOSITORY] Network connected, calling remote data source...');
        final subjectModels = await remoteDataSource.getSubjects(teacherId);
        print('📚 [REPOSITORY] Successfully fetched ${subjectModels.length} subject models from remote data source');
        
        final subjects = subjectModels.map((model) => Subject(
          id: model.id,
          subject: model.subject,
          teacherId: model.teacherId,
        )).toList();
        
        print('📚 [REPOSITORY] Successfully converted ${subjects.length} subject models to entities');
        return Right(subjects);
      } catch (e) {
        print('📚 [REPOSITORY ERROR] Failed to fetch subjects: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📚 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
}

