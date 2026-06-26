part of 'notes_assignments_page.dart';

abstract class NotesAssignmentsEvent extends Equatable {
  const NotesAssignmentsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NotesAssignmentsEvent {
  final String schoolId;
  const LoadNotes(this.schoolId);
  @override
  List<Object> get props => [schoolId];
}

class LoadNotesByGrade extends NotesAssignmentsEvent {
  final String schoolId;
  final String grade;
  const LoadNotesByGrade(this.schoolId, this.grade);
  @override
  List<Object> get props => [schoolId, grade];
} 