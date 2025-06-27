part of 'free_videos_bloc.dart';

abstract class FreeVideosState extends Equatable {
  const FreeVideosState();

  @override
  List<Object> get props => [];
}

class FreeVideosInitial extends FreeVideosState {}
class FreeVideosLoading extends FreeVideosState {}
class FreeVideosLoaded extends FreeVideosState {
  final List<Video> videos;
  const FreeVideosLoaded(this.videos);
  @override
  List<Object> get props => [videos];
}
class FreeVideosError extends FreeVideosState {
  final String message;
  const FreeVideosError(this.message);
  @override
  List<Object> get props => [message];
} 