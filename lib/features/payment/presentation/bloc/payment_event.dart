part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class CreatePaymentRequested extends PaymentEvent {
  final String userId;
  final String teacherId;
  final String grade;
  final String subject;
  final String month;
  final int year;
  final double amount;
  final String? slipUrl;

  const CreatePaymentRequested({
    required this.userId,
    required this.teacherId,
    required this.grade,
    required this.subject,
    required this.month,
    required this.year,
    required this.amount,
    this.slipUrl,
  });

  // @override
  // List<Object>! get props => [userId, teacherId, grade, subject, month, year, amount, slipUrl];
}

class CheckAccessRequested extends PaymentEvent {
  final String userId;
  final String grade;
  final String subject;
  final String month;
  final int year;

  const CheckAccessRequested({
    required this.userId,
    required this.grade,
    required this.subject,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [userId, grade, subject, month, year];
}

class LoadPayAccountDetails extends PaymentEvent {
  final String teacherId;

  const LoadPayAccountDetails(this.teacherId);

  @override
  List<Object> get props => [teacherId];
} 