part of 'free_classes_page.dart';

abstract class FreeClassesEvent extends Equatable {
  const FreeClassesEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeClassesEvent {
  final String teacherId;
  const LoadFreeVideos(this.teacherId);
  @override
  List<Object> get props => [teacherId];
} 