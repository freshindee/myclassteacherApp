part of 'notes_assignments_page.dart';

abstract class NotesAssignmentsEvent extends Equatable {
  const NotesAssignmentsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NotesAssignmentsEvent {
  final String teacherId;
  const LoadNotes(this.teacherId);
  @override
  List<Object> get props => [teacherId];
}

class LoadNotesByGrade extends NotesAssignmentsEvent {
  final String teacherId;
  final String grade;
  const LoadNotesByGrade(this.teacherId, this.grade);
  @override
  List<Object> get props => [teacherId, grade];
} 