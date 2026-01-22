import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/note.dart';
import '../repositories/note_repository.dart';

class GetFreeNotes implements UseCase<List<Note>, GetFreeNotesParams> {
  final NoteRepository repository;
  
  GetFreeNotes(this.repository);
  
  @override
  Future<Either<Failure, List<Note>>> call(GetFreeNotesParams params) async {
    return await repository.getFreeNotes(params.teacherId, grade: params.grade);
  }
}

class GetFreeNotesParams extends Equatable {
  final String teacherId;
  final String? grade;
  
  const GetFreeNotesParams({
    required this.teacherId,
    this.grade,
  });

  @override
  List<Object?> get props => [teacherId, grade];
}
