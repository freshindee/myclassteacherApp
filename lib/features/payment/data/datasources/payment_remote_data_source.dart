import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';
import '../models/subscription_model.dart';
import '../models/pay_account_details_model.dart';
import '../../domain/entities/payment.dart';

abstract class PaymentRemoteDataSource {
  Future<void> createPayment(Payment payment);
  Future<bool> hasAccess(String userId, String grade, String subject, int month, int year);
  Future<List<SubscriptionModel>> getUserSubscriptions(String userId);
  Future<List<PaymentModel>> getUserPayments(String userId, {String? schoolId});
  Future<PayAccountDetailsModel?> getPayAccountDetails(String schoolId);
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  final FirebaseFirestore firestore;

  PaymentRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> createPayment(Payment payment) async {
    try {
      final schoolId = payment.teacherId;
      final monthName = _monthName(payment.month);
      print('🎬 PaymentDataSource: Saving to schools/$schoolId/payments');

      final paymentData = {
        'student_id': payment.userId,
        'month': monthName,
        'amount': payment.amount,
        'date': Timestamp.fromDate(payment.createdAt),
        'grade': payment.grade,
        'class_name': payment.className ?? '',
        'class_subject_id': payment.classSubjectId ?? '',
        'subject_name': payment.subject,
        'slip_image_path': payment.slipUrl ?? '',
        'status': 'pending',
        'payment_method': 'bank',
      };
      final schoolRef = firestore.collection('schools').doc(schoolId);
      final paymentsRef = schoolRef.collection('payments');
      final paymentDocRef = paymentsRef.doc();

      // Save payment + enrollment in a single batch (atomic).
      final batch = firestore.batch();
      batch.set(paymentDocRef, paymentData);

      // Also save enrollment row when class_subject_id is available.
      // Document id format: student_id_class_subject_id
      final classSubjectId = (payment.classSubjectId ?? '').trim();
      if (classSubjectId.isNotEmpty) {
        String classId = '';
        String subjectId = '';
        try {
          final classSubjectSnap =
              await schoolRef.collection('class_subjects').doc(classSubjectId).get();
          if (classSubjectSnap.exists) {
            final data = classSubjectSnap.data() ?? {};
            classId = (data['class_id'] ?? data['classId'] ?? data['class'] ?? '')
                .toString()
                .trim();
            subjectId = (data['subject_id'] ?? data['subjectId'] ?? data['subject'] ?? '')
                .toString()
                .trim();
          }
        } catch (e) {
          // Keep empty class/subject ids if lookup fails, but continue save.
          print('⚠️ PaymentDataSource: class_subject lookup failed for $classSubjectId: $e');
        }

        final enrollmentDocId = '${payment.userId}_$classSubjectId';
        final enrollmentData = {
          'academic_model': 'subject_based',
          'class_id': classId,
          'class_subject_id': classSubjectId,
          'enrolled_at': Timestamp.now(),
          'enrolled_by': payment.userId,
          'status': 'active',
          'student_id': payment.userId,
          'subject_id': subjectId,
          'teacher_id': schoolId,
        };
        final enrollmentRef = schoolRef.collection('enrollments').doc(enrollmentDocId);
        batch.set(enrollmentRef, enrollmentData, SetOptions(merge: true));
      }

      await batch.commit();
      print('🎬 PaymentDataSource: Payment saved to schools/$schoolId/payments');
      if (classSubjectId.isNotEmpty) {
        print(
            '🎬 PaymentDataSource: Enrollment upserted to schools/$schoolId/enrollments/${payment.userId}_$classSubjectId');
      }
    } catch (e) {
      print('❌ PaymentDataSource: Failed to create payment: $e');
      throw Exception('Failed to create payment: $e');
    }
  }

  static const List<String> _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static String _monthName(int monthNumber) {
    if (monthNumber < 1 || monthNumber > 12) return 'January';
    return _monthNames[monthNumber];
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
  Future<List<PaymentModel>> getUserPayments(String userId, {String? schoolId}) async {
    try {
      print('💰 [API REQUEST] PaymentDataSource.getUserPayments called with userId: $userId, schoolId: $schoolId');

      QuerySnapshot<Map<String, dynamic>> querySnapshot;
      if (schoolId != null && schoolId.isNotEmpty) {
        querySnapshot = await firestore
            .collection('schools')
            .doc(schoolId)
            .collection('payments')
            .where('student_id', isEqualTo: userId)
            .get();
      } else {
        querySnapshot = await firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
      }

      print('💰 [API RESPONSE] Found ${querySnapshot.docs.length} payment documents for userId: $userId${schoolId != null ? ', schoolId: $schoolId' : ''}');

      final payments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return PaymentModel.fromJson({
          'id': doc.id,
          ...data,
        });
      }).toList();

      if (payments.isNotEmpty && payments.length > 1) {
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
  Future<PayAccountDetailsModel?> getPayAccountDetails(String schoolId) async {
    try {
      print('💰 [API REQUEST] PaymentDataSource.getPayAccountDetails called with schoolId: $schoolId');
      
      final querySnapshot = await firestore
          .collection('schools')
          .doc(schoolId)
          .collection('pay_account_details')
          .limit(1)
          .get();
      
      print('💰 [API RESPONSE] Found ${querySnapshot.docs.length} pay account detail documents for schoolId: $schoolId');
      
      if (querySnapshot.docs.isEmpty) {
        print('💰 [API RESPONSE] No pay account details found for schoolId: $schoolId');
        return null;
      }
      
      final doc = querySnapshot.docs.first;
      final data = doc.data();
      print('💰 [API RESPONSE] Pay account detail document ${doc.id}: $data');
      
      final payAccountDetails = PayAccountDetailsModel.fromJson({
        'id': doc.id,
        ...data,
        'teacherId': schoolId,
      });
      
      print('💰 [API RESPONSE] Successfully parsed pay account details: ${payAccountDetails.slider1Url}');
      return payAccountDetails;
    } catch (e) {
      print('💰 [API ERROR] Error fetching pay account details: $e');
      throw Exception('Failed to fetch pay account details: $e');
    }
  }
} 