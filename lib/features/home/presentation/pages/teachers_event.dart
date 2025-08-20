part of 'teachers_bloc.dart';

abstract class TeachersEvent extends Equatable {
  const TeachersEvent();
  @override
  List<Object> get props => [];
}
class LoadTeachers extends TeachersEvent {
  final String teacherId;
  const LoadTeachers(this.teacherId);
  @override
  List<Object> get props => [teacherId];
} 