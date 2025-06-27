import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/usecases/create_payment.dart';
import '../../domain/usecases/check_access.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../../../../core/utils/month_utils.dart';
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final CreatePayment createPayment;
  final CheckAccess checkAccess;

  PaymentBloc({
    required this.createPayment,
    required this.checkAccess,
  }) : super(PaymentInitial()) {
    on<CreatePaymentRequested>(_onCreatePaymentRequested);
    on<CheckAccessRequested>(_onCheckAccessRequested);
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

    final payment = Payment(
      id: paymentId,
      userId: event.userId,
      grade: event.grade,
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
} 