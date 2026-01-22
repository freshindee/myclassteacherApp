part of 'free_notes_bloc.dart';

abstract class FreeNotesEvent extends Equatable {
  const FreeNotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadFreeNotes extends FreeNotesEvent {
  final String teacherId;
  final String? grade;
  
  const LoadFreeNotes(this.teacherId, {this.grade});
  
  @override
  List<Object?> get props => [teacherId, grade];
}
