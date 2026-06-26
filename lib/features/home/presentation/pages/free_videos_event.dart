part of 'free_videos_bloc.dart';

abstract class FreeVideosEvent extends Equatable {
  const FreeVideosEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeVideosEvent {
  final String schoolId;
  const LoadFreeVideos(this.schoolId);
  @override
  List<Object> get props => [schoolId];
}

class LoadFreeVideosByGrade extends FreeVideosEvent {
  final String schoolId;
  final String grade;
  const LoadFreeVideosByGrade(this.schoolId, this.grade);
  @override
  List<Object> get props => [schoolId, grade];
} 