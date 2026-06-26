import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<Either<Failure, List<Note>>> getNotes(String schoolId);
  Future<Either<Failure, List<Note>>> getNotesByGrade(String schoolId, String grade);
} 