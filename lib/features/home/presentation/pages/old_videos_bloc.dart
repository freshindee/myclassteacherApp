import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/video.dart';
import '../../domain/usecases/get_videos.dart';
import '../../../../core/usecases.dart';
import '../../../../core/utils/month_utils.dart';

part 'old_videos_event.dart';
part 'old_videos_state.dart';

class OldVideosBloc extends Bloc<OldVideosEvent, OldVideosState> {
  final GetVideos getVideos;

  OldVideosBloc({
    required this.getVideos,
  }) : super(OldVideosInitial()) {
    on<FetchOldVideos>(_onFetchOldVideos);
  }

  Future<void> _onFetchOldVideos(
    FetchOldVideos event,
    Emitter<OldVideosState> emit,
  ) async {
    emit(OldVideosLoading());
    developer.log('DEBUG: Entered _onFetchOldVideos with userId: [1m${event.userId}[0m', name: 'OldVideosBloc');

    try {
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      
      // Fetch all old videos for the user (no filters)
      final videosResult = await getVideos(
        const GetVideosParams(), // No filters, fetch all
      ).timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Timeout while fetching videos');
      });

      await videosResult.fold(
        (failure) async {
          developer.log('DEBUG: Failed to fetch old videos: ${failure.message}', name: 'OldVideosBloc');
          emit(OldVideosError(failure.message));
        },
        (videos) async {
          developer.log('DEBUG-----------: Successfully fetched ${videos.length} total videos.', name: 'OldVideosBloc');
          
          // Filter for past months of the current year
          final pastVideos = videos.where((video) {
            return video.year == currentYear && video.month != null && video.month! < currentMonth;
          }).toList();

          developer.log('DEBUG-----------: Filtered to ${pastVideos.length} past videos.', name: 'OldVideosBloc');
          developer.log('Fetched videos: ' + pastVideos.map((v) => 'title=${v.title}, thumb=${v.thumb}, url=${v.youtubeUrl}').join('; '), name: 'OldVideosBloc');
          developer.log('DEBUG-----------: Emitting OldVideosLoaded state.', name: 'OldVideosBloc');
          emit(OldVideosLoaded(videos: pastVideos));
        },
      );
    } catch (e, stack) {
      developer.log('DEBUG-------------: Exception in _onFetchOldVideos: $e', name: 'OldVideosBloc', error: e, stackTrace: stack);
      emit(OldVideosError('Exception: $e'));
    }
  }
} 