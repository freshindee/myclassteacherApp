part of 'free_classes_page.dart';

abstract class FreeClassesEvent extends Equatable {
  const FreeClassesEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeClassesEvent {
  final String schoolId;
  const LoadFreeVideos(this.schoolId);
  @override
  List<Object> get props => [schoolId];
} 