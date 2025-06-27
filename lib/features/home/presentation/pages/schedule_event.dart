part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class LoadGrades extends ScheduleEvent {}

class LoadTimetable extends ScheduleEvent {
  final String grade;

  const LoadTimetable(this.grade);

  @override
  List<Object> get props => [grade];
} 