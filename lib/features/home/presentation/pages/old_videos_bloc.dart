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
      final currentYear = event.year ?? now.year;
      final currentMonth = event.month ?? now.month;
      
      // Extract grade number from "Grade X" format if needed
      String? gradeValue = event.grade;
      if (gradeValue != null && gradeValue.contains('Grade')) {
        gradeValue = gradeValue.replaceAll(RegExp(r'[^0-9]'), '');
      }
      
      // Fetch videos with the provided filters
      final videosResult = await getVideos(
        GetVideosParams(
          userId: event.userId,
          teacherId: event.teacherId,
          grade: gradeValue,
          subject: event.subject,
          month: currentMonth,
          year: currentYear,
          // Don't filter by accessLevel to get both paid and free videos
        ),
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
          developer.log('Fetched videos: ' + videos.map((v) => 'title=${v.title}, thumb=${v.thumb}, url=${v.youtubeUrl}').join('; '), name: 'OldVideosBloc');
          developer.log('DEBUG-----------: Emitting OldVideosLoaded state.', name: 'OldVideosBloc');
          emit(OldVideosLoaded(videos: videos));
        },
      );
    } catch (e, stack) {
      developer.log('DEBUG-------------: Exception in _onFetchOldVideos: $e', name: 'OldVideosBloc', error: e, stackTrace: stack);
      emit(OldVideosError('Exception: $e'));
    }
  }
} 