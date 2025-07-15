import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetNotesByGrade {
  final NoteRepository repository;
  GetNotesByGrade(this.repository);
  Future<Either<Failure, List<Note>>> call(String grade) async {
    return await repository.getNotesByGrade(grade);
  }
} 