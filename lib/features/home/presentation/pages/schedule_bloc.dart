import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/timetable.dart';
import '../../domain/usecases/get_timetable_by_grade.dart';
import '../../domain/usecases/get_available_grades.dart';
import '../../../../core/usecases.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final GetAvailableGrades getAvailableGrades;
  final GetTimetableByGrade getTimetableByGrade;

  ScheduleBloc({
    required this.getAvailableGrades,
    required this.getTimetableByGrade,
  }) : super(ScheduleInitial()) {
    on<LoadGrades>(_onLoadGrades);
    on<LoadTimetable>(_onLoadTimetable);
  }

  Future<void> _onLoadGrades(
    LoadGrades event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    final result = await getAvailableGrades(event.teacherId);
    result.fold(
      (failure) => emit(ScheduleError(failure.toString())),
      (grades) => emit(GradesLoaded(grades)),
    );
  }

  Future<void> _onLoadTimetable(
    LoadTimetable event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());
    final result = await getTimetableByGrade(GetTimetableByGradeParams(teacherId: event.teacherId, grade: event.grade));
    result.fold(
      (failure) => emit(ScheduleError(failure.toString())),
      (timetables) => emit(TimetableLoaded(timetables, event.grade)),
    );
  }
} 