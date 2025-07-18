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
  Future<Either<Failure, List<Timetable>>> getTimetableByGrade(String grade) async {
    if (await networkInfo.isConnected) {
      try {
        developer.log('📱 Fetching timetable for grade $grade from repository...', name: 'TimetableRepository');
        final timetableModels = await remoteDataSource.getTimetableByGrade(grade);
        developer.log('📱 Converting ${timetableModels.length} timetable models to entities', name: 'TimetableRepository');
        
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
        )).toList();

        developer.log('✅ Successfully converted ${timetables.length} timetable entries', name: 'TimetableRepository');
        return Right(timetables);
      } catch (e) {
        developer.log('❌ Failed to fetch timetable for grade $grade: ${e.toString()}', name: 'TimetableRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      developer.log('❌ No internet connection for timetable', name: 'TimetableRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableGrades() async {
    if (await networkInfo.isConnected) {
      try {
        developer.log('📱 Fetching available grades from repository...', name: 'TimetableRepository');
        final grades = await remoteDataSource.getAvailableGrades();
        developer.log('✅ Successfully fetched ${grades.length} available grades', name: 'TimetableRepository');
        return Right(grades);
      } catch (e) {
        developer.log('❌ Failed to fetch available grades: ${e.toString()}', name: 'TimetableRepository');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      developer.log('❌ No internet connection for grades', name: 'TimetableRepository');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 