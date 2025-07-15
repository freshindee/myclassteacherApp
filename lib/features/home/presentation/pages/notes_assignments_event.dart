part of 'notes_assignments_page.dart';

abstract class NotesAssignmentsEvent extends Equatable {
  const NotesAssignmentsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NotesAssignmentsEvent {}

class LoadNotesByGrade extends NotesAssignmentsEvent {
  final String grade;
  const LoadNotesByGrade(this.grade);
  @override
  List<Object> get props => [grade];
} 