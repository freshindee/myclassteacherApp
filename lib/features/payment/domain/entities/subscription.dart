import 'package:equatable/equatable.dart';

class Subscription extends Equatable {
  final String id;
  final String userId;
  final String grade;
  final String subject;
  final int month;
  final int year;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String paymentId;

  const Subscription({
    required this.id,
    required this.userId,
    required this.grade,
    required this.subject,
    required this.month,
    required this.year,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.paymentId,
  });

  @override
  List<Object> get props => [
        id,
        userId,
        grade,
        subject,
        month,
        year,
        startDate,
        endDate,
        isActive,
        paymentId,
      ];
} 