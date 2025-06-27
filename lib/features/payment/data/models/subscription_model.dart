import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';

class SubscriptionModel extends Equatable {
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

  const SubscriptionModel({
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
  List<Object> get props => [id, userId, grade, subject, month, year, startDate, endDate, isActive, paymentId];

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      grade: json['grade'] as String,
      subject: json['subject'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] as bool,
      paymentId: json['paymentId'] as String,
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
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'paymentId': paymentId,
    };
  }

  Subscription toEntity() {
    return Subscription(
      id: id,
      userId: userId,
      grade: grade,
      subject: subject,
      month: month,
      year: year,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      paymentId: paymentId,
    );
  }
} 