import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/payment.dart';
import '../entities/subscription.dart';
import '../entities/pay_account_details.dart';

abstract class PaymentRepository {
  Future<Either<Failure, void>> createPayment(Payment payment);
  Future<Either<Failure, bool>> hasAccess(String userId, String grade, String subject, int month, int year);
  Future<Either<Failure, List<Subscription>>> getUserSubscriptions(String userId);
  Future<Either<Failure, List<Payment>>> getUserPayments(String userId, {String? teacherId});
  Future<Either<Failure, PayAccountDetails?>> getPayAccountDetails(String teacherId);
} 