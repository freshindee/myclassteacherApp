part of 'schedule_bloc.dart';

abstract class ScheduleEvent extends Equatable {
  const ScheduleEvent();

  @override
  List<Object> get props => [];
}

class LoadGrades extends ScheduleEvent {
  final String schoolId;
  const LoadGrades(this.schoolId);
  @override
  List<Object> get props => [schoolId];
}

class LoadTimetable extends ScheduleEvent {
  final String schoolId;
  final String grade;

  const LoadTimetable(this.schoolId, this.grade);

  @override
  List<Object> get props => [schoolId, grade];
} 