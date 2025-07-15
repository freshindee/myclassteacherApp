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
    final now = DateTime.now();
    final currentMonth = now.month; // Use integer month number
    final currentYear = now.year;
    print('🎬 currentMonth: $currentMonth');
    print('🎬 currentYear: $currentYear');
    print('🎬 ====================================');
    
    developer.log('🎬 Fetching videos with parameters: userId=${event.userId}, month=$currentMonth, year=$currentYear', name: 'ClassVideosBloc');
    
    try {

      // 1. Fetch all videos for the current month
      final getVideosParams = GetVideosParams(
        userId: event.userId,
        grade: event.grade,
        month: currentMonth, 
        year: currentYear
      );
      
      print('🎬 Sending GetVideosParams to repository:');
      print('🎬   - userId: ${getVideosParams.userId}');
      print('🎬   - month: ${getVideosParams.month}');
      print('🎬   - year: ${getVideosParams.year}');
      print('🎬   - grade: ${getVideosParams.grade}');
      print('🎬   - subject: ${getVideosParams.subject}');
      
      final videosResult = await getVideos(getVideosParams).timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Timeout while fetching videos');
      });
      
      await videosResult.fold(
        (failure) async {
          print('DEBUG: Failed to fetch videos: [31m${failure.message}[0m');
          developer.log('Failed to fetch videos: ${failure.message}', name: 'ClassVideosBloc');
          emit(ClassVideosError(failure.message));
        },
        (videos) async {
          print('DEBUG: Successfully fetched ${videos.length} videos.');
          developer.log('Successfully fetched ${videos.length} videos.', name: 'ClassVideosBloc');
          for (var v in videos) {
            print('DEBUG: Video: title=${v.title}, grade=${v.grade}, subject=${v.subject}, month=${v.month}, year=${v.year}, accessLevel=${v.accessLevel}');
          }

          // Filter videos for current month/year (using integer comparison)
          print('🎬 Filtering videos for current month/year:');
          print('🎬   - Filter criteria: month=$currentMonth, year=$currentYear');
          print('🎬   - Total videos before filtering: ${videos.length}');
          
          final currentMonthVideos = videos.where((v) => (v.month == currentMonth) && (v.year == currentYear)).toList();
          print('🎬 Videos for current month: ${currentMonthVideos.length}');
          
          for (var v in currentMonthVideos) {
            print('🎬 CurrentMonthVideo: title=${v.title}, grade=${v.grade}, subject=${v.subject}, month=${v.month}, year=${v.year}, accessLevel=${v.accessLevel}');
          }

          // 2. Fetch all payments for the user for the current month
          print('🎬 ====== PAYMENT FETCH PARAMETERS ======');
          print('🎬 userId: ${event.userId}');
          print('🎬 ======================================');
          
          final getUserPaymentsParams = GetUserPaymentsParams(userId: event.userId);
          
          print('🎬 Sending GetUserPaymentsParams to repository:');
          print('🎬   - userId: ${getUserPaymentsParams.userId}');
          print('🎬   - Note: Fetching ALL payments for this user (not filtered by month/year yet)');
          
          final paymentsResult = await getUserPayments(getUserPaymentsParams).timeout(const Duration(seconds: 60), onTimeout: () {
            throw Exception('Timeout while fetching payments');
          });
          await paymentsResult.fold(
            (failure) async {
              print('DEBUG: Failed to fetch payments: [31m${failure.message}[0m');
              developer.log('Failed to fetch payments: ${failure.message}', name: 'ClassVideosBloc');
              emit(ClassVideosError(failure.message));
            },
            (payments) async {
              print('DEBUG: Successfully fetched ${payments.length} payments.');
              developer.log('Successfully fetched ${payments.length} payments.', name: 'ClassVideosBloc');
              for (var p in payments) {
                print('DEBUG: Payment: userId=${p.userId}, grade=${p.grade}, subject=${p.subject}, month=${p.month}, year=${p.year}, status=${p.status}');
              }

              // Filter payments for current month/year and completed status (using integer comparison)
              print('🎬 Filtering payments for current month/year and approved status:');
              print('🎬   - Filter criteria: month=$currentMonth, year=$currentYear, status=approved');
              print('🎬   - Total payments before filtering: ${payments.length}');
              
              final currentMonthPayments = payments.where((p) => p.month == currentMonth && p.year == currentYear && p.status == 'approved').toList();
              print('🎬 Payments for current month: ${currentMonthPayments.length}');
              
              for (var p in currentMonthPayments) {
                print('🎬 CurrentMonthPayment: userId=${p.userId}, grade=${p.grade}, subject=${p.subject}, month=${p.month}, year=${p.year}, status=${p.status}');
              }

              // 3. For each payment, find videos that match the payment's grade and subject from the videos list
              print('🎬 Matching paid videos with payments:');
              final paidVideos = <Video>[];
              var tv;

              for (var payment in currentMonthPayments) {
                print('🎬 Checking payment: grade=${payment.grade}, subject=${payment.subject}');
                final matches = currentMonthVideos.where((v) =>
                  v.accessLevel == 'paid' &&
                  v.grade == payment.grade &&
                  v.subject == payment.subject
                ).toList();
                print('🎬 Found ${matches.length} matching paid videos for grade=${payment.grade}, subject=${payment.subject}');
                for (var match in matches) {
                  print('🎬   - Matching video: ${match.title} (accessLevel=${match.accessLevel})');
                }
                paidVideos.addAll(matches);
              }
              
              print('🎬 Total paid videos found: ${paidVideos.length}');

              // 4. Combine all free videos and the paid videos found above into a final list
              print('🎬 Combining free and paid videos:');
              final freeVideos = currentMonthVideos.where((v) => v.accessLevel == 'free').toList();
              print('🎬 Free videos for current month: ${freeVideos.length}');
              for (var free in freeVideos) {
                print('🎬   - Free video: ${free.title} (grade=${free.grade}, subject=${free.subject})');
              }
              
              final allVideos = [...freeVideos, ...paidVideos];
              print('🎬 Final video list to display: ${allVideos.length} videos');
              print('🎬   - Free videos: ${freeVideos.length}');
              print('🎬   - Paid videos: ${paidVideos.length}');

              // 5. Display this final list in the class videos page
              emit(ClassVideosLoaded(videos: allVideos));
            },
          );
        },
      );
    } catch (e, stack) {
      print('DEBUG: Exception in _onFetchClassVideos: $e');
      developer.log('Exception in _onFetchClassVideos: $e', name: 'ClassVideosBloc', error: e, stackTrace: stack);
      emit(ClassVideosError('Exception: $e'));
    }
  }
} 