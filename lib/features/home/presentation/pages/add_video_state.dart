part of 'add_video_bloc.dart';

class AddVideoState extends Equatable {
  final String title;
  final String description;
  final String youtubeUrl;
  final String thumb;
  final String grade;
  final String subject;
  final String accessLevel;
  final FormzStatus status;
  final String? errorMessage;
  final Video? addedVideo;

  const AddVideoState({
    this.title = '',
    this.description = '',
    this.youtubeUrl = '',
    this.thumb = '',
    this.grade = '',
    this.subject = '',
    this.accessLevel = 'free',
    this.status = FormzStatus.pure,
    this.errorMessage,
    this.addedVideo,
  });

  AddVideoState copyWith({
    String? title,
    String? description,
    String? youtubeUrl,
    String? thumb,
    String? grade,
    String? subject,
    String? accessLevel,
    FormzStatus? status,
    String? errorMessage,
    Video? addedVideo,
  }) {
    return AddVideoState(
      title: title ?? this.title,
      description: description ?? this.description,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      thumb: thumb ?? this.thumb,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      accessLevel: accessLevel ?? this.accessLevel,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      addedVideo: addedVideo ?? this.addedVideo,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        youtubeUrl,
        thumb,
        grade,
        subject,
        accessLevel,
        status,
        errorMessage,
        addedVideo,
      ];
} 