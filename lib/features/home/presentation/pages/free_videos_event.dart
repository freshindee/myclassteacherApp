part of 'free_videos_bloc.dart';

abstract class FreeVideosEvent extends Equatable {
  const FreeVideosEvent();

  @override
  List<Object> get props => [];
}

class LoadFreeVideos extends FreeVideosEvent {} 