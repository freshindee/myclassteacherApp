import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/today_class.dart';
import '../../domain/usecases/get_today_classes.dart';
import '../../../../core/usecases.dart';

part 'today_classes_event.dart';
part 'today_classes_state.dart';

class TodayClassesBloc extends Bloc<TodayClassesEvent, TodayClassesState> {
  final GetTodayClasses getTodayClasses;
  TodayClassesBloc({required this.getTodayClasses}) : super(TodayClassesInitial()) {
    on<LoadTodayClasses>(_onLoadTodayClasses);
  }

  Future<void> _onLoadTodayClasses(
    LoadTodayClasses event,
    Emitter<TodayClassesState> emit,
  ) async {
    emit(TodayClassesLoading());
    final result = await getTodayClasses(event.teacherId);
    result.fold(
      (failure) => emit(TodayClassesError(failure.toString())),
      (classes) => emit(TodayClassesLoaded(classes)),
    );
  }
} 