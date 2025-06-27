part of 'teachers_bloc.dart';

abstract class TeachersEvent extends Equatable {
  const TeachersEvent();
  @override
  List<Object> get props => [];
}
class LoadTeachers extends TeachersEvent {} 