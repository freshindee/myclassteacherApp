part of 'today_classes_bloc.dart';

abstract class TodayClassesEvent extends Equatable {
  const TodayClassesEvent();
  @override
  List<Object> get props => [];
}
class LoadTodayClasses extends TodayClassesEvent {} 