import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/note.dart';
import '../../domain/usecases/get_free_notes.dart';
import '../../../../core/usecases.dart';
import '../../../../core/errors/failures.dart';

part 'free_notes_event.dart';
part 'free_notes_state.dart';

class FreeNotesBloc extends Bloc<FreeNotesEvent, FreeNotesState> {
  final GetFreeNotes getFreeNotes;

  FreeNotesBloc({required this.getFreeNotes}) : super(FreeNotesInitial()) {
    on<LoadFreeNotes>(_onLoadFreeNotes);
  }

  Future<void> _onLoadFreeNotes(
    LoadFreeNotes event,
    Emitter<FreeNotesState> emit,
  ) async {
    emit(FreeNotesLoading());
    final params = GetFreeNotesParams(teacherId: event.teacherId, grade: event.grade);
    final result = await getFreeNotes(params);
    result.fold(
      (failure) => emit(FreeNotesError(_mapFailureToMessage(failure))),
      (notes) => emit(FreeNotesLoaded(notes)),
    );
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
