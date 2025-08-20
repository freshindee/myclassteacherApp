import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_data_source.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final TeacherRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TeacherRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Teacher>>> getTeachers(String teacherId) async {
    print('👨‍🏫 [REPOSITORY] TeacherRepository.getTeachers called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('👨‍🏫 [REPOSITORY] Network connected, calling remote data source...');
        final teacherModels = await remoteDataSource.getTeachers(teacherId);
        print('👨‍🏫 [REPOSITORY] Successfully fetched ${teacherModels.length} teacher models from remote data source');
        
        final teachers = teacherModels.map((model) => Teacher(
          id: model.id,
          name: model.name,
          subject: model.subject,
          grade: model.grade,
          phone: model.phone,
          image: model.image,
        )).toList();
        
        print('👨‍🏫 [REPOSITORY] Successfully converted ${teachers.length} teacher models to entities');
        return Right(teachers);
      } catch (e) {
        print('👨‍🏫 [REPOSITORY ERROR] Failed to fetch teachers: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('👨‍🏫 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 