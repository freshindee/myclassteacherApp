part of 'class_videos_bloc.dart';

abstract class ClassVideosState extends Equatable {
  const ClassVideosState();
  
  @override
  List<Object> get props => [];
}

class ClassVideosInitial extends ClassVideosState {}

class ClassVideosLoading extends ClassVideosState {}

class ClassVideosLoaded extends ClassVideosState {
  final List<Video> videos;

  const ClassVideosLoaded({required this.videos});

  @override
  List<Object> get props => [videos];
}

class ClassVideosError extends ClassVideosState {
  final String message;

  const ClassVideosError(this.message);

  @override
  List<Object> get props => [message];
} 