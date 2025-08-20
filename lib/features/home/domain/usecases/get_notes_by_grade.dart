import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';
import '../../../../core/usecases.dart';

class GetNotesByGrade implements UseCase<List<Note>, GetNotesByGradeParams> {
  final NoteRepository repository;
  GetNotesByGrade(this.repository);
  
  @override
  Future<Either<Failure, List<Note>>> call(GetNotesByGradeParams params) async {
    return await repository.getNotesByGrade(params.teacherId, params.grade);
  }
}

class GetNotesByGradeParams {
  final String teacherId;
  final String grade;
  
  GetNotesByGradeParams({required this.teacherId, required this.grade});
} 