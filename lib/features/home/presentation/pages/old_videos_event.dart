part of 'old_videos_bloc.dart';

abstract class OldVideosEvent extends Equatable {
  const OldVideosEvent();

  @override
  List<Object> get props => [];
}

class FetchOldVideos extends OldVideosEvent {
  final String userId;

  const FetchOldVideos({required this.userId});

  @override
  List<Object> get props => [userId];
} 