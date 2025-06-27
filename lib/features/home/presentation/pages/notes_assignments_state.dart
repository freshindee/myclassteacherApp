part of 'notes_assignments_page.dart';

abstract class NotesAssignmentsState extends Equatable {
  const NotesAssignmentsState();

  @override
  List<Object> get props => [];
}

class NotesAssignmentsInitial extends NotesAssignmentsState {}

class NotesAssignmentsLoading extends NotesAssignmentsState {}

class NotesAssignmentsLoaded extends NotesAssignmentsState {
  final List<Note> notes;

  const NotesAssignmentsLoaded(this.notes);

  @override
  List<Object> get props => [notes];
}

class NotesAssignmentsError extends NotesAssignmentsState {
  final String message;

  const NotesAssignmentsError(this.message);

  @override
  List<Object> get props => [message];
} 