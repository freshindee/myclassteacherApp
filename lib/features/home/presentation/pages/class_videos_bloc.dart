import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/video.dart';
import '../../domain/usecases/get_videos.dart';
import '../../../payment/domain/usecases/get_user_payments.dart';
import '../../../payment/domain/entities/payment.dart';
import '../../../../core/usecases.dart';
import '../../../../core/utils/month_utils.dart';

part 'class_videos_event.dart';
part 'class_videos_state.dart';

class ClassVideosBloc extends Bloc<ClassVideosEvent, ClassVideosState> {
  final GetVideos getVideos;
  final GetUserPayments getUserPayments;

  ClassVideosBloc({
    required this.getVideos,
    required this.getUserPayments,
  }) : super(ClassVideosInitial()) {
    on<FetchClassVideos>(_onFetchClassVideos);
  }

  Future<void> _onFetchClassVideos(
    FetchClassVideos event,
    Emitter<ClassVideosState> emit,
  ) async {
    emit(ClassVideosLoading());
    
    // Enhanced logging for parameters being sent
    print('🎬 ====== VIDEO FETCH PARAMETERS ======');
    print('🎬 userId: ${event.userId}');
    print('🎬 teacherId: ${event.teacherId}');
    final now = DateTime.now();
    final currentMonth = now.month; // Use integer month number
    final currentYear = now.year;
    print('🎬 currentMonth: $currentMonth');
    print('🎬 currentYear: $currentYear');
    print('🎬 ====================================');
    
    developer.log('🎬 Fetching videos with parameters: userId=${event.userId}, teacherId=${event.teacherId}, month=$currentMonth, year=$currentYear', name: 'ClassVideosBloc');
    
    try {

      // 1. Fetch all videos for the current month
      final getVideosParams = GetVideosParams(
        userId: event.userId,
        teacherId: event.teacherId,
        grade: event.grade,
        subject: event.subject,
        month: currentMonth, 
        year: currentYear
      );
      
      print('🎬 Sending GetVideosParams to repository:');
      print('🎬   - userId: ${getVideosParams.userId}');
      print('🎬   - teacherId: ${getVideosParams.teacherId}');
      print('🎬   - month: ${getVideosParams.month}');
      print('🎬   - year: ${getVideosParams.year}');
      print('🎬   - grade: ${getVideosParams.grade}');
      print('🎬   - subject: ${getVideosParams.subject}');
      
      final videosResult = await getVideos(getVideosParams).timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Timeout while fetching videos');
      });
      
      await videosResult.fold(
        (failure) async {
          print('DEBUG: Failed to fetch videos:  [31m${failure.message} [0m');
          developer.log('Failed to fetch videos: ${failure.message}', name: 'ClassVideosBloc');
          emit(ClassVideosError(failure.message));
        },
        (videos) async {
          print('DEBUG: Successfully fetched ${videos.length} videos.');
          developer.log('Successfully fetched ${videos.length} videos.', name: 'ClassVideosBloc');
          for (var v in videos) {
            print('DEBUG: Video: title=${v.title}, grade=${v.grade}, subject=${v.subject}, month=${v.month}, year=${v.year}, accessLevel=${v.accessLevel}');
          }
          emit(ClassVideosLoaded(videos: videos));
        },
      );
    } catch (e, stack) {
      print('DEBUG: Exception in _onFetchClassVideos: $e');
      developer.log('Exception in _onFetchClassVideos: $e', name: 'ClassVideosBloc', error: e, stackTrace: stack);
      emit(ClassVideosError('Exception: $e'));
    }
  }
} 