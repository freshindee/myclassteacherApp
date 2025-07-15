part of 'notes_assignments_page.dart';

class NotesAssignmentsBloc extends Bloc<NotesAssignmentsEvent, NotesAssignmentsState> {
  final GetNotes getNotes;
  final GetNotesByGrade getNotesByGrade;

  NotesAssignmentsBloc({required this.getNotes, required this.getNotesByGrade}) : super(NotesAssignmentsInitial()) {
    on<LoadNotes>((event, emit) async {
      emit(NotesAssignmentsLoading());
      final result = await getNotes(NoParams());
      result.fold(
        (failure) {
          emit(NotesAssignmentsError(_mapFailureToMessage(failure)));
        },
        (notes) => emit(NotesAssignmentsLoaded(notes)),
      );
    });
    on<LoadNotesByGrade>((event, emit) async {
      emit(NotesAssignmentsLoading());
      final result = await getNotesByGrade(event.grade);
      result.fold(
        (failure) {
          emit(NotesAssignmentsError(_mapFailureToMessage(failure)));
        },
        (notes) => emit(NotesAssignmentsLoaded(notes)),
      );
    });
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      default:
        return 'An unexpected error occurred';
    }
  }
} 