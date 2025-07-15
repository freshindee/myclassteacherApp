import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_free_videos.dart';
import '../../domain/usecases/get_free_videos_by_grade.dart';
import '../../../../core/usecases.dart';

part 'free_videos_event.dart';
part 'free_videos_state.dart';

class FreeVideosBloc extends Bloc<FreeVideosEvent, FreeVideosState> {
  final GetFreeVideos getFreeVideos;
  final GetFreeVideosByGrade getFreeVideosByGrade;

  FreeVideosBloc({required this.getFreeVideos, required this.getFreeVideosByGrade}) : super(FreeVideosInitial()) {
    on<LoadFreeVideos>(_onLoadFreeVideos);
    on<LoadFreeVideosByGrade>(_onLoadFreeVideosByGrade);
  }

  Future<void> _onLoadFreeVideos(
    LoadFreeVideos event,
    Emitter<FreeVideosState> emit,
  ) async {
    emit(FreeVideosLoading());
    final result = await getFreeVideos(NoParams());
    result.fold(
      (failure) => emit(FreeVideosError(failure.toString())),
      (videos) => emit(FreeVideosLoaded(videos)),
    );
  }

  Future<void> _onLoadFreeVideosByGrade(
    LoadFreeVideosByGrade event,
    Emitter<FreeVideosState> emit,
  ) async {
    emit(FreeVideosLoading());
    final result = await getFreeVideosByGrade(event.grade);
    result.fold(
      (failure) => emit(FreeVideosError(failure.toString())),
      (videos) => emit(FreeVideosLoaded(videos)),
    );
  }
} 