import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String grade;
  final String subject;
  final int month;
  final int year;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? slipUrl;

  const PaymentModel({
    required this.id,
    required this.userId,
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
  List<Object?> get props => [id, userId, grade, subject, month, year, amount, status, createdAt, completedAt, slipUrl];

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      grade: json['grade'] as String,
      subject: json['subject'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null 
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      slipUrl: json['slipUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'grade': grade,
      'subject': subject,
      'month': month,
      'year': year,
      'amount': amount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'slipUrl': slipUrl,
    };
  }

  Payment toEntity() {
    return Payment(
      id: id,
      userId: userId,
      grade: grade,
      subject: subject,
      month: month,
      year: year,
      amount: amount,
      status: status,
      createdAt: createdAt,
      completedAt: completedAt,
      slipUrl: slipUrl,
    );
  }
} 