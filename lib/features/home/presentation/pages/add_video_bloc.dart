import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/add_video.dart';

part 'add_video_event.dart';
part 'add_video_state.dart';

class AddVideoBloc extends Bloc<AddVideoEvent, AddVideoState> {
  final AddVideo addVideo;

  AddVideoBloc({required this.addVideo}) : super(const AddVideoState()) {
    on<VideoTitleChanged>(_onVideoTitleChanged);
    on<VideoDescriptionChanged>(_onVideoDescriptionChanged);
    on<VideoUrlChanged>(_onVideoUrlChanged);
    on<VideoThumbChanged>(_onVideoThumbChanged);
    on<VideoGradeChanged>(_onVideoGradeChanged);
    on<VideoSubjectChanged>(_onVideoSubjectChanged);
    on<VideoAccessLevelChanged>(_onVideoAccessLevelChanged);
    on<AddVideoSubmitted>(_onAddVideoSubmitted);
  }

  void _onVideoTitleChanged(VideoTitleChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(title: event.title));
  }

  void _onVideoDescriptionChanged(VideoDescriptionChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(description: event.description));
  }

  void _onVideoUrlChanged(VideoUrlChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(youtubeUrl: event.url));
  }

  void _onVideoThumbChanged(VideoThumbChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(thumb: event.thumb));
  }

  void _onVideoGradeChanged(VideoGradeChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(grade: event.grade));
  }

  void _onVideoSubjectChanged(VideoSubjectChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(subject: event.subject));
  }

  void _onVideoAccessLevelChanged(VideoAccessLevelChanged event, Emitter<AddVideoState> emit) {
    emit(state.copyWith(accessLevel: event.accessLevel));
  }

  Future<void> _onAddVideoSubmitted(AddVideoSubmitted event, Emitter<AddVideoState> emit) async {
    if (state.title.isEmpty || state.description.isEmpty || state.youtubeUrl.isEmpty || state.thumb.isEmpty) {
      emit(state.copyWith(status: FormzStatus.submissionFailure, errorMessage: 'Please fill all required fields'));
      return;
    }

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final params = AddVideoParams(
      title: state.title,
      description: state.description,
      youtubeUrl: state.youtubeUrl,
      thumb: state.thumb,
      grade: state.grade.isEmpty ? null : state.grade,
      subject: state.subject.isEmpty ? null : state.subject,
      accessLevel: state.accessLevel,
    );

    final result = await addVideo(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          errorMessage: failure.message,
        ));
      },
      (video) {
        emit(state.copyWith(
          status: FormzStatus.submissionSuccess,
          addedVideo: video,
        ));
      },
    );
  }
} 