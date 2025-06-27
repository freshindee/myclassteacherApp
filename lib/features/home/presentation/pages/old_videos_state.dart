part of 'old_videos_bloc.dart';

abstract class OldVideosState extends Equatable {
  const OldVideosState();
  
  @override
  List<Object> get props => [];
}

class OldVideosInitial extends OldVideosState {}

class OldVideosLoading extends OldVideosState {}

class OldVideosLoaded extends OldVideosState {
  final List<Video> videos;

  const OldVideosLoaded({required this.videos});

  @override
  List<Object> get props => [videos];
}

class OldVideosError extends OldVideosState {
  final String message;

  const OldVideosError(this.message);

  @override
  List<Object> get props => [message];
} 