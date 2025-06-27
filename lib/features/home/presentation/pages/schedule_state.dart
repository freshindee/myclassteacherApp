part of 'schedule_bloc.dart';

abstract class ScheduleState extends Equatable {
  const ScheduleState();

  @override
  List<Object> get props => [];
}

class ScheduleInitial extends ScheduleState {}
class ScheduleLoading extends ScheduleState {}
class GradesLoaded extends ScheduleState {
  final List<String> grades;
  const GradesLoaded(this.grades);
  @override
  List<Object> get props => [grades];
}
class TimetableLoaded extends ScheduleState {
  final List<Timetable> timetables;
  final String selectedGrade;
  const TimetableLoaded(this.timetables, this.selectedGrade);
  @override
  List<Object> get props => [timetables, selectedGrade];
}
class ScheduleError extends ScheduleState {
  final String message;
  const ScheduleError(this.message);
  @override
  List<Object> get props => [message];
} 