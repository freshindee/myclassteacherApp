part of 'add_video_bloc.dart';

abstract class AddVideoEvent extends Equatable {
  const AddVideoEvent();

  @override
  List<Object> get props => [];
}

class VideoTitleChanged extends AddVideoEvent {
  final String title;

  const VideoTitleChanged(this.title);

  @override
  List<Object> get props => [title];
}

class VideoDescriptionChanged extends AddVideoEvent {
  final String description;

  const VideoDescriptionChanged(this.description);

  @override
  List<Object> get props => [description];
}

class VideoUrlChanged extends AddVideoEvent {
  final String url;

  const VideoUrlChanged(this.url);

  @override
  List<Object> get props => [url];
}

class VideoThumbChanged extends AddVideoEvent {
  final String thumb;

  const VideoThumbChanged(this.thumb);

  @override
  List<Object> get props => [thumb];
}

class VideoGradeChanged extends AddVideoEvent {
  final String grade;

  const VideoGradeChanged(this.grade);

  @override
  List<Object> get props => [grade];
}

class VideoSubjectChanged extends AddVideoEvent {
  final String subject;

  const VideoSubjectChanged(this.subject);

  @override
  List<Object> get props => [subject];
}

class VideoAccessLevelChanged extends AddVideoEvent {
  final String accessLevel;

  const VideoAccessLevelChanged(this.accessLevel);

  @override
  List<Object> get props => [accessLevel];
}

class AddVideoSubmitted extends AddVideoEvent {} 