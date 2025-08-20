import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotes implements UseCase<List<Note>, String> {
  final NoteRepository repository;

  GetNotes(this.repository);

  @override
  Future<Either<Failure, List<Note>>> call(String teacherId) async {
    return await repository.getNotes(teacherId);
  }
} 