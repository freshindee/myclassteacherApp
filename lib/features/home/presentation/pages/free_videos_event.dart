part of 'free_videos_bloc.dart';

abstract class FreeVideosEvent extends Equatable {
  const FreeVideosEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeVideosEvent {
  final String teacherId;
  const LoadFreeVideos(this.teacherId);
  @override
  List<Object> get props => [teacherId];
}

class LoadFreeVideosByGrade extends FreeVideosEvent {
  final String teacherId;
  final String grade;
  const LoadFreeVideosByGrade(this.teacherId, this.grade);
  @override
  List<Object> get props => [teacherId, grade];
} 