part of 'free_videos_bloc.dart';

abstract class FreeVideosEvent extends Equatable {
  const FreeVideosEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeVideosEvent {}

class LoadFreeVideosByGrade extends FreeVideosEvent {
  final String grade;
  const LoadFreeVideosByGrade(this.grade);
  @override
  List<Object> get props => [grade];
} 