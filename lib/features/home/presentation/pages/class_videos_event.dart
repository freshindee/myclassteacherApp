part of 'class_videos_bloc.dart';

abstract class ClassVideosEvent extends Equatable {
  const ClassVideosEvent();

  @override
  List<Object> get props => [];
}

class FetchClassVideos extends ClassVideosEvent {
  final String userId;
  final String? grade;
  final String? subject;
  final List<dynamic> payments;

  const FetchClassVideos({required this.userId, this.grade, this.subject, required this.payments});

  @override
  List<Object> get props => [userId, grade ?? '', subject ?? '', payments];
} 