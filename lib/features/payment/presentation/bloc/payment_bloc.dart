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
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePayment createPayment;
  final CheckAccess checkAccess;
  final GetPayAccountDetails getPayAccountDetails;

  PaymentBloc({
    required this.createPayment,
    required this.checkAccess,
    required this.getPayAccountDetails,
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
    print('🎬   - grade: ${event.grade} (grade number only)');
    print('🎬   - subject: ${event.subject}');
    print('🎬   - month: $monthNumber (converted from: ${event.month})');
    print('🎬   - year: ${event.year}');
    print('🎬   - amount: ${event.amount}');

    final payment = Payment(
      id: paymentId,
      userId: event.userId,
      grade: event.grade, // This now contains only the grade number
      subject: event.subject,
      month: monthNumber, // Store as integer
      year: event.year,
      amount: event.amount,
      status: 'completed', // For demo purposes, assume payment is successful
      createdAt: now,
      completedAt: now,
      slipUrl: event.slipUrl,
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

    print('💰 [BLOC] PaymentBloc: Loading pay account details for teacherId: ${event.teacherId}');

    final result = await getPayAccountDetails(event.teacherId);
    
    result.fold(
      (failure) {
        print('💰 [BLOC ERROR] Failed to load pay account details: ${failure.message}');
        emit(PayAccountDetailsError(failure.message));
      },
      (payAccountDetails) {
        if (payAccountDetails != null) {
          print('💰 [BLOC] Successfully loaded pay account details with slider URL: ${payAccountDetails.slider1Url}');
          emit(PayAccountDetailsLoaded(payAccountDetails.slider1Url));
        } else {
          print('💰 [BLOC] No pay account details found for teacherId: ${event.teacherId}');
          emit(const PayAccountDetailsError('No account details found for this teacher'));
        }
      },
    );
  }
} 