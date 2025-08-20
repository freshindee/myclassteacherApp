import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_remote_data_source.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NoteRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Note>>> getNotes(String teacherId) async {
    print('📝 [REPOSITORY] NoteRepository.getNotes called with teacherId: $teacherId');
    
    if (await networkInfo.isConnected) {
      try {
        print('📝 [REPOSITORY] Network connected, calling remote data source...');
        final noteModels = await remoteDataSource.getNotes(teacherId);
        print('📝 [REPOSITORY] Successfully fetched ${noteModels.length} note models from remote data source');
        
        final notes = noteModels.map((model) => Note(
          id: model.id,
          grade: model.grade,
          title: model.title,
          description: model.description,
          pdfUrl: model.pdfUrl,
        )).toList();
        
        print('📝 [REPOSITORY] Successfully converted ${notes.length} note models to entities');
        return Right(notes);
      } catch (e) {
        print('📝 [REPOSITORY ERROR] Failed to fetch notes: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📝 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getNotesByGrade(String teacherId, String grade) async {
    print('📝 [REPOSITORY] NoteRepository.getNotesByGrade called with teacherId: $teacherId, grade: $grade');
    
    if (await networkInfo.isConnected) {
      try {
        print('📝 [REPOSITORY] Network connected, calling remote data source...');
        final noteModels = await remoteDataSource.getNotesByGrade(teacherId, grade);
        print('📝 [REPOSITORY] Successfully fetched ${noteModels.length} note models from remote data source for grade $grade');
        
        final notes = noteModels.map((model) => Note(
          id: model.id,
          grade: model.grade,
          title: model.title,
          description: model.description,
          pdfUrl: model.pdfUrl,
        )).toList();
        
        print('📝 [REPOSITORY] Successfully converted ${notes.length} note models to entities for grade $grade');
        return Right(notes);
      } catch (e) {
        print('📝 [REPOSITORY ERROR] Failed to fetch notes by grade: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('📝 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 