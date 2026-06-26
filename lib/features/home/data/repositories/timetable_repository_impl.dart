import 'package:dartz/dartz.dart';
import 'dart:developer' as developer;
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/timetable_remote_data_source.dart';
import '../models/timetable_model.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/repositories/timetable_repository.dart';

class TimetableRepositoryImpl implements TimetableRepository {
  final TimetableRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TimetableRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Timetable>>> getTimetableByGrade(String schoolId, String grade) async {
    print('📅 [REPOSITORY] TimetableRepository.getTimetableByGrade called with schoolId: $schoolId, grade: $grade');
    
    if (await networkInfo.isConnected) {
      try {
        print('📅 [REPOSITORY] Network connected, calling remote data source...');
        final timetableModels = await remoteDataSource.getTimetableByGrade(schoolId, grade);
        print('📅 [REPOSITORY] Successfully fetched ${timetableModels.length} timetable models from remote data source for grade $grade');
        
        final timetables = timetableModels.map((model) => Timetable(
          id: model.id,
          grade: model.grade,
          subject: model.subject,
          day: model.day,
          time: model.time,
          teacher: model.teacher,
          teacherId: model.teacherId,
          room: model.room,
          description: model.description,
          index: model.index,
          time2: model.time2,
          time3: model.time3,
          displayId: model.displayId,
          topic: model.topic,
        )).toList();
        
        print('📅 [REPOSITORY] Successfully converted ${timetables.length} timetable models to entities for grade $grade');
        return Right(timetables);
      } catch (e) {
        print('📅 [REPOSITORY ERROR] Failed to fetch timetable by grade: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📅 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableGrades(String schoolId) async {
    print('📅 [REPOSITORY] TimetableRepository.getAvailableGrades called with schoolId: $schoolId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📅 [REPOSITORY] Network connected, calling remote data source...');
        final grades = await remoteDataSource.getAvailableGrades(schoolId);
        print('📅 [REPOSITORY] Successfully fetched ${grades.length} available grades from remote data source: $grades');
        return Right(grades);
      } catch (e) {
        print('📅 [REPOSITORY ERROR] Failed to fetch available grades: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📅 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 