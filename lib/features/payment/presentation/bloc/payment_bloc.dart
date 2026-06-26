import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/pay_account_details.dart';
import '../../domain/usecases/create_payment.dart';
import '../../domain/usecases/check_access.dart';
import '../../domain/usecases/get_pay_account_details.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../../../../core/utils/month_utils.dart';
import '../../../../core/services/master_data_service.dart';
import '../../../../core/services/school_cache_service.dart';
import '../../../../core/services/school_cache_sync_service.dart';
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePayment createPayment;
  final CheckAccess checkAccess;
  final GetPayAccountDetails getPayAccountDetails;
  final SchoolCacheService schoolCacheService;
  final SchoolCacheSyncService schoolCacheSyncService;

  PaymentBloc({
    required this.createPayment,
    required this.checkAccess,
    required this.getPayAccountDetails,
    required this.schoolCacheService,
    required this.schoolCacheSyncService,
  }) : super(PaymentInitial()) {
    on<CreatePaymentRequested>(_onCreatePaymentRequested);
    on<CheckAccessRequested>(_onCheckAccessRequested);
    on<LoadPayAccountDetails>(_onLoadPayAccountDetails);
  }

  Future<void> _onCreatePaymentRequested(
    CreatePaymentRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final paymentId = const Uuid().v4();
    final subscriptionId = const Uuid().v4();
    
    // Calculate subscription dates (1 month from payment date)
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0); // Last day of current month

    // Convert month name to month number
    final monthNumber = MonthUtils.getMonthNumber(event.month);

    print('🎬 PaymentBloc: Creating payment with parameters:');
    print('🎬   - userId: ${event.userId}');
    print('🎬   - teacherId: ${event.teacherId}');
    print('🎬   - grade: ${event.grade} (grade number only)');
    print('🎬   - subject: ${event.subject}');
    print('🎬   - month: $monthNumber (converted from: ${event.month})');
    print('🎬   - year: ${event.year}');
    print('🎬   - amount: ${event.amount}');

    final payment = Payment(
      id: paymentId,
      userId: event.userId,
      teacherId: event.teacherId,
      grade: event.grade,
      subject: event.subject,
      month: monthNumber,
      year: event.year,
      amount: event.amount,
      status: 'pending',
      createdAt: now,
      completedAt: null,
      slipUrl: event.slipUrl,
      className: event.className,
      classSubjectId: event.classSubjectId,
    );

    final subscription = Subscription(
      id: subscriptionId,
      userId: event.userId,
      grade: event.grade,
      subject: event.subject,
      month: monthNumber, // Store as integer
      year: event.year,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      paymentId: paymentId,
    );

    final result = await createPayment(payment);
    
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (_) => emit(PaymentSuccess()),
    );
  }

  Future<void> _onCheckAccessRequested(
    CheckAccessRequested event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    // Convert month name to month number
    final monthNumber = MonthUtils.getMonthNumber(event.month);

    final params = CheckAccessParams(
      userId: event.userId,
      grade: event.grade,
      subject: event.subject,
      month: monthNumber, // Pass as integer
      year: event.year,
    );

    final result = await checkAccess(params);
    
    result.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (hasAccess) => emit(AccessChecked(hasAccess)),
    );
  }

  Future<void> _onLoadPayAccountDetails(
    LoadPayAccountDetails event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PayAccountDetailsLoading());

    final schoolId = event.schoolId;
    print('💰 [BLOC] PaymentBloc: Loading bank details for schoolId: $schoolId');

    try {
      // 1. Bank details from schools/{schoolId}/app_config: try cache first
      final appConfig = await schoolCacheService.getAppConfigSingle(schoolId);
      if (appConfig != null && appConfig.bankDetails.isNotEmpty) {
        print('💰 [BLOC] Loaded ${appConfig.bankDetails.length} bank details from app_config cache');
        emit(PayAccountDetailsLoaded(appConfig.bankDetails));
        return;
      }

      // 2. If cache empty, fetch app_config from Firestore (bank_details array)
      final bankDetailsFromFirestore =
          await schoolCacheSyncService.fetchBankDetailsFromAppConfig(schoolId);
      if (bankDetailsFromFirestore.isNotEmpty) {
        print('💰 [BLOC] Loaded ${bankDetailsFromFirestore.length} bank details from Firestore app_config');
        emit(PayAccountDetailsLoaded(bankDetailsFromFirestore));
        return;
      }

      // 3. Teachers: master data fallback
      final masterData = await MasterDataService.getTeacherMasterData();
      if (masterData != null && masterData.bankDetails.isNotEmpty) {
        print('💰 [BLOC] Loaded ${masterData.bankDetails.length} bank details from master data');
        emit(PayAccountDetailsLoaded(masterData.bankDetails));
        return;
      }

      // 4. Fallback: remote pay_account_details
      print('💰 [BLOC] No bank details in cache, falling back to remote');
      final result = await getPayAccountDetails(schoolId);
      result.fold(
        (failure) {
          print('💰 [BLOC ERROR] Failed to load pay account details: ${failure.message}');
          emit(PayAccountDetailsError(failure.message));
        },
        (payAccountDetails) {
          if (payAccountDetails != null) {
            emit(PayAccountDetailsLoaded([payAccountDetails.slider1Url]));
          } else {
            emit(const PayAccountDetailsError('No account details found for this teacher'));
          }
        },
      );
    } catch (e) {
      print('💰 [BLOC ERROR] Error loading bank details: $e');
      emit(PayAccountDetailsError('Failed to load bank details: $e'));
    }
  }
} 