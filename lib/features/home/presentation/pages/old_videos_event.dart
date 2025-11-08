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
  final String? subject;
  final int? month;
  final int? year;

  const FetchOldVideos({
    required this.userId,
    required this.teacherId,
    this.grade,
    this.subject,
    this.month,
    this.year,
  });

  @override
  List<Object> get props => [userId, teacherId, grade ?? '', subject ?? '', month ?? 0, year ?? 0];
} 