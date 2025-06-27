part of 'class_videos_bloc.dart';

abstract class ClassVideosEvent extends Equatable {
  const ClassVideosEvent();

  @override
  List<Object> get props => [];
}

class FetchClassVideos extends ClassVideosEvent {
  final String userId;

  const FetchClassVideos({required this.userId});

  @override
  List<Object> get props => [userId];
} 