import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_free_videos.dart';
import '../../../../core/usecases.dart';

part 'free_videos_event.dart';
part 'free_videos_state.dart';

class FreeVideosBloc extends Bloc<FreeVideosEvent, FreeVideosState> {
  final GetFreeVideos getFreeVideos;

  FreeVideosBloc({required this.getFreeVideos}) : super(FreeVideosInitial()) {
    on<LoadFreeVideos>(_onLoadFreeVideos);
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
} 