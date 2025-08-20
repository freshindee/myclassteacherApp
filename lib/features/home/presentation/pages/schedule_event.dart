part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class LoadGrades extends ScheduleEvent {
  final String teacherId;
  const LoadGrades(this.teacherId);
  @override
  List<Object> get props => [teacherId];
}

class LoadTimetable extends ScheduleEvent {
  final String teacherId;
  final String grade;

  const LoadTimetable(this.teacherId, this.grade);

  @override
  List<Object> get props => [teacherId, grade];
} 