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
    return await repository.getNotesByGrade(params.schoolId, params.grade);
  }
}

class GetNotesByGradeParams {
  final String schoolId;
  final String grade;
  
  GetNotesByGradeParams({required this.schoolId, required this.grade});
} 