part of 'today_classes_bloc.dart';

abstract class TodayClassesState extends Equatable {
  const TodayClassesState();
  @override
  List<Object> get props => [];
}
class TodayClassesInitial extends TodayClassesState {}
class TodayClassesLoading extends TodayClassesState {}
class TodayClassesLoaded extends TodayClassesState {
  final List<TodayClass> classes;
  const TodayClassesLoaded(this.classes);
  @override
  List<Object> get props => [classes];
}
class TodayClassesError extends TodayClassesState {
  final String message;
  const TodayClassesError(this.message);
  @override
  List<Object> get props => [message];
} 