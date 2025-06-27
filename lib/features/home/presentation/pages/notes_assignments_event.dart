part of 'notes_assignments_page.dart';

abstract class NotesAssignmentsEvent extends Equatable {
  const NotesAssignmentsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotes extends NotesAssignmentsEvent {} 