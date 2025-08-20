import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';

abstract class NoteRepository {
  Future<Either<Failure, List<Note>>> getNotes(String teacherId);
  Future<Either<Failure, List<Note>>> getNotesByGrade(String teacherId, String grade);
} 