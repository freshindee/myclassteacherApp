import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/month_utils.dart';
import '../../domain/entities/payment.dart';

class PaymentModel extends Equatable {
  final String id;
  final String userId;
  final String teacherId;
  final String grade;
  final String subject;
  final int month;
  final int year;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? slipUrl;
  final String? className;
  final String? classSubjectId;

  const PaymentModel({
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
    this.className,
    this.classSubjectId,
  });

  @override
  List<Object?> get props => [id, userId, teacherId, grade, subject, month, year, amount, status, createdAt, completedAt, slipUrl, className, classSubjectId];

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final uid = json['userId'] ?? json['student_id'];
    return PaymentModel(
      id: json['id'] as String,
      userId: uid != null ? uid.toString() : '',
      teacherId: json['teacherId'] as String? ?? '',
      grade: (json['grade'] ?? '').toString(),
      subject: (json['subject'] ?? json['subject_name'] ?? '').toString(),
      month: _monthFromJson(json['month']),
      year: json['year'] as int? ?? DateTime.now().year,
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: json['createdAt'] != null ? (json['createdAt'] as Timestamp).toDate() : (json['date'] != null ? (json['date'] as Timestamp).toDate() : DateTime.now()),
      completedAt: json['completedAt'] != null ? (json['completedAt'] as Timestamp).toDate() : null,
      slipUrl: (json['slipUrl'] ?? json['slip_image_path']) as String?,
      className: json['className'] as String? ?? json['class_name'] as String?,
      classSubjectId: json['classSubjectId'] as String? ?? json['class_subject_id'] as String?,
    );
  }

  static int _monthFromJson(dynamic v) {
    if (v == null) return 1;
    if (v is int) return v;
    if (v is String) {
      try {
        return MonthUtils.getMonthNumber(v);
      } catch (_) {
        return 1;
      }
    }
    return 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'teacherId': teacherId,
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
      teacherId: teacherId,
      grade: grade,
      subject: subject,
      month: month,
      year: year,
      amount: amount,
      status: status,
      createdAt: createdAt,
      completedAt: completedAt,
      slipUrl: slipUrl,
      className: className,
      classSubjectId: classSubjectId,
    );
  }
} 