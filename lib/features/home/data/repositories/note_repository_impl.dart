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
  Future<Either<Failure, List<Note>>> getNotes() async {
    if (await networkInfo.isConnected) {
      try {
        final noteModels = await remoteDataSource.getNotes();
        final List<Note> notes = noteModels.map((model) => Note(
          id: model.id,
          grade: model.grade,
          title: model.title,
          description: model.description,
          pdfUrl: model.pdfUrl,
        )).toList();
        return Right(notes);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Note>>> getNotesByGrade(String grade) async {
    if (await networkInfo.isConnected) {
      try {
        final noteModels = await remoteDataSource.getNotesByGrade(grade);
        final List<Note> notes = noteModels.map((model) => Note(
          id: model.id,
          grade: model.grade,
          title: model.title,
          description: model.description,
          pdfUrl: model.pdfUrl,
        )).toList();
        return Right(notes);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }
} 