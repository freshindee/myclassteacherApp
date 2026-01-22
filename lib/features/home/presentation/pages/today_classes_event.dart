part of 'today_classes_bloc.dart';

abstract class TodayClassesEvent extends Equatable {
  const TodayClassesEvent();
  @override
  List<Object?> get props => [];
}
class LoadTodayClasses extends TodayClassesEvent {
  final String teacherId;
  final String? grade;
  final String? subject;
  const LoadTodayClasses(this.teacherId, {this.grade, this.subject});
  @override
  List<Object?> get props => [teacherId, grade, subject];
} 