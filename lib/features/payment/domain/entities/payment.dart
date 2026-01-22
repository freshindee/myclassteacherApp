import 'package:equatable/equatable.dart';

class Payment extends Equatable {
  final String id;
  final String userId;
  final String teacherId;
  final String grade;
  final String subject;
  final int month;
  final int year;
  final double amount;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? slipUrl;

  const Payment({
    required this.id,
    required this.userId,
    required this.teacherId,
    required this.grade,
    required this.subject,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.slipUrl,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        teacherId,
        grade,
        subject,
        month,
        year,
        amount,
        status,
        createdAt,
        completedAt,
        slipUrl,
      ];
} 