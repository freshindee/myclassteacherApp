part of 'old_videos_bloc.dart';

abstract class OldVideosEvent extends Equatable {
  const OldVideosEvent();

  @override
  List<Object> get props => [];
}

class FetchOldVideos extends OldVideosEvent {
  final String userId;
  final String teacherId;
  final String? grade;

  const FetchOldVideos({required this.userId, required this.teacherId, this.grade});

  @override
  List<Object> get props => [userId, teacherId, grade ?? ''];
} 