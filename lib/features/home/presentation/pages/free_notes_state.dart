part of 'free_notes_bloc.dart';

abstract class FreeNotesState extends Equatable {
  const FreeNotesState();
  @override
  List<Object?> get props => [];
}

class FreeNotesInitial extends FreeNotesState {}

class FreeNotesLoading extends FreeNotesState {}

class FreeNotesLoaded extends FreeNotesState {
  final List<Note> notes;
  
  const FreeNotesLoaded(this.notes);
  
  @override
  List<Object?> get props => [notes];
}

class FreeNotesError extends FreeNotesState {
  final String message;
  
  const FreeNotesError(this.message);
  
  @override
  List<Object?> get props => [message];
}
