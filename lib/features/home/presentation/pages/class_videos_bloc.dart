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
    print('DEBUG: Entered _onFetchClassVideos for userId: [1m${event.userId}[0m');
    try {
      final now = DateTime.now();
      final currentMonth = now.month; // Use integer month number
      final currentYear = now.year;
      print('DEBUG: Current month: $currentMonth, year: $currentYear');

      // 1. Fetch all videos for the current month
      final videosResult = await getVideos(GetVideosParams(month: currentMonth, year: currentYear)).timeout(const Duration(seconds: 60), onTimeout: () {
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
          final currentMonthVideos = videos.where((v) => (v.month == currentMonth) && (v.year == currentYear)).toList();
          print('DEBUG: Videos for current month: ${currentMonthVideos.length}');
          for (var v in currentMonthVideos) {
            print('DEBUG: CurrentMonthVideo: title=${v.title}, grade=${v.grade}, subject=${v.subject}, month=${v.month}, year=${v.year}, accessLevel=${v.accessLevel}');
          }

          // 2. Fetch all payments for the user for the current month
          final paymentsResult = await getUserPayments(GetUserPaymentsParams(userId: event.userId)).timeout(const Duration(seconds: 60), onTimeout: () {
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
              final currentMonthPayments = payments.where((p) => p.month == currentMonth && p.year == currentYear && p.status == 'completed').toList();
              print('DEBUG: Payments for current month: ${currentMonthPayments.length}');
              for (var p in currentMonthPayments) {
                print('DEBUG: CurrentMonthPayment: userId=${p.userId}, grade=${p.grade}, subject=${p.subject}, month=${p.month}, year=${p.year}, status=${p.status}');
              }

              // 3. For each payment, find videos that match the payment's grade and subject from the videos list
              final paidVideos = <Video>[];
              var tv;

              for (var payment in currentMonthPayments) {
                final matches = currentMonthVideos.where((v) =>
                  v.accessLevel == 'paid' &&
                  v.grade == payment.grade &&
                  v.subject == payment.subject
                ).toList();
                print('=Paid=========${payment.grade}, subject=${payment.subject}');
                paidVideos.addAll(matches);
              }

              // 4. Combine all free videos and the paid videos found above into a final list
              final freeVideos = currentMonthVideos.where((v) => v.accessLevel == 'free').toList();
              print('DEBUG: Free videos for current month: ${freeVideos.length}');
              final allVideos = [...freeVideos, ...paidVideos];
              print('DEBUG: Final video list to display: ${allVideos.length}');

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