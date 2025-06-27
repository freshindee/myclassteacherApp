import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentRemoteDataSource {
  Future<void> createPayment(Payment payment);
  Future<bool> hasAccess(String userId, String grade, String subject, int month, int year);
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId);
  Future<List<PaymentModel>> getUserPayments(String userId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createPayment(Payment payment) async {
    try {
      final paymentData = {
        'userId': payment.userId,
        'grade': payment.grade,
        'subject': payment.subject,
        'month': payment.month,
        'year': payment.year,
        'amount': payment.amount,
        'status': payment.status,
        'createdAt': Timestamp.fromDate(payment.createdAt),
        'completedAt': payment.completedAt != null ? Timestamp.fromDate(payment.completedAt!) : null,
        'slipUrl': payment.slipUrl,
      };

      await firestore.collection('payments').add(paymentData);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<bool> hasAccess(String userId, String grade, String subject, int month, int year) async {
    try {
      final querySnapshot = await firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('grade', isEqualTo: grade)
          .where('subject', isEqualTo: subject)
          .where('month', isEqualTo: month)
          .where('year', isEqualTo: year)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check access: $e');
    }
  }

  @override
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => SubscriptionModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user subscriptions: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getUserPayments(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user payments: $e');
    }
  }
} 