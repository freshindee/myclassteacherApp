import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../models/pay_account_details_model.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentRemoteDataSource {
  Future<void> createPayment(Payment payment);
  Future<bool> hasAccess(String userId, String grade, String subject, int month, int year);
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId);
  Future<List<PaymentModel>> getUserPayments(String userId, {String? teacherId});
  Future<PayAccountDetailsModel?> getPayAccountDetails(String teacherId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createPayment(Payment payment) async {
    try {
      print('🎬 PaymentDataSource: Creating payment in Firestore with data:');
      print('🎬   - userId: ${payment.userId}');
      print('🎬   - grade: ${payment.grade} (grade number only)');
      print('🎬   - subject: ${payment.subject}');
      print('🎬   - month: ${payment.month}');
      print('🎬   - year: ${payment.year}');
      print('🎬   - amount: ${payment.amount}');
      print('🎬   - status: ${payment.status}');
      
      final paymentData = {
        'userId': payment.userId,
        'grade': payment.grade, // This now contains only the grade number
        'subject': payment.subject,
        'month': payment.month,
        'year': payment.year,
        'amount': payment.amount,
        'status': payment.status,
        'createdAt': Timestamp.fromDate(payment.createdAt),
        'completedAt': payment.completedAt != null ? Timestamp.fromDate(payment.completedAt!) : null,
        'slipUrl': payment.slipUrl,
      };

      print('🎬 PaymentDataSource: Saving payment data to Firestore: $paymentData');
      await firestore.collection('payments').add(paymentData);
      print('🎬 PaymentDataSource: Payment saved successfully to Firestore');
    } catch (e) {
      print('❌ PaymentDataSource: Failed to create payment: $e');
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
  Future<List<PaymentModel>> getUserPayments(String userId, {String? teacherId}) async {
    try {
      print('💰 [API REQUEST] PaymentDataSource.getUserPayments called with userId: $userId, teacherId: $teacherId');
      
      Query<Map<String, dynamic>> query = firestore
          .collection('payments')
          .where('userId', isEqualTo: userId);
      
      // Filter by teacherId if provided
      if (teacherId != null && teacherId.isNotEmpty) {
        query = query.where('teacherId', isEqualTo: teacherId);
        print('💰 [API REQUEST] Applied filter: teacherId = $teacherId');
      }
      
      // When filtering by teacherId, we can't use orderBy without a composite index
      // So we'll fetch without orderBy and sort in memory
      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      if (teacherId != null && teacherId.isNotEmpty) {
        // Fetch without orderBy to avoid index requirement
        querySnapshot = await query.get();
      } else {
        // When only userId filter, we can use orderBy
        querySnapshot = await query.orderBy('createdAt', descending: true).get();
      }
      
      print('💰 [API RESPONSE] Found ${querySnapshot.docs.length} payment documents for userId: $userId${teacherId != null ? ', teacherId: $teacherId' : ''}');
      
      final payments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('💰 [API RESPONSE] Payment document ${doc.id}: $data');
        return PaymentModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();
      
      // Sort by createdAt descending if we fetched without orderBy
      if (teacherId != null && teacherId.isNotEmpty) {
        payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      print('💰 [API RESPONSE] Successfully parsed ${payments.length} payments');
      return payments;
    } catch (e) {
      print('💰 [API ERROR] Error fetching user payments: $e');
      throw Exception('Failed to fetch user payments: $e');
    }
  }

  @override
  Future<PayAccountDetailsModel?> getPayAccountDetails(String teacherId) async {
    try {
      print('💰 [API REQUEST] PaymentDataSource.getPayAccountDetails called with teacherId: $teacherId');
      
      final querySnapshot = await firestore
          .collection('pay_account_details')
          .where('teacherId', isEqualTo: teacherId)
          .limit(1)
          .get();
      
      print('💰 [API RESPONSE] Found ${querySnapshot.docs.length} pay account detail documents for teacherId: $teacherId');
      
      if (querySnapshot.docs.isEmpty) {
        print('💰 [API RESPONSE] No pay account details found for teacherId: $teacherId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      print('💰 [API RESPONSE] Pay account detail document ${doc.id}: $data');
      
      final payAccountDetails = PayAccountDetailsModel.fromJson({
        'id': doc.id,
        ...data,
      });
      
      print('💰 [API RESPONSE] Successfully parsed pay account details: ${payAccountDetails.slider1Url}');
      return payAccountDetails;
    } catch (e) {
      print('💰 [API ERROR] Error fetching pay account details: $e');
      throw Exception('Failed to fetch pay account details: $e');
    }
  }
} 