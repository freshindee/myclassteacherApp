import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/payment_remote_data_source.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/pay_account_details.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> createPayment(Payment payment) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createPayment(payment);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAccess(String userId, String grade, String subject, int month, int year) async {
    if (await networkInfo.isConnected) {
      try {
        final hasAccess = await remoteDataSource.hasAccess(userId, grade, subject, month, year);
        return Right(hasAccess);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Subscription>>> getUserSubscriptions(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final subscriptionModels = await remoteDataSource.getUserSubscriptions(userId);
        final subscriptions = subscriptionModels.map((model) => model.toEntity()).toList();
        return Right(subscriptions);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getUserPayments(String userId, {String? schoolId}) async {
    if (await networkInfo.isConnected) {
      try {
        final paymentModels = await remoteDataSource.getUserPayments(userId, schoolId: schoolId);
        final payments = paymentModels.map((model) => model.toEntity()).toList();
        return Right(payments);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, PayAccountDetails?>> getPayAccountDetails(String schoolId) async {
    if (await networkInfo.isConnected) {
      try {
        print('💰 [REPOSITORY] PaymentRepository.getPayAccountDetails called with schoolId: $schoolId');
        final payAccountDetailsModel = await remoteDataSource.getPayAccountDetails(schoolId);
        if (payAccountDetailsModel == null) {
          print('💰 [REPOSITORY] No pay account details found for schoolId: $schoolId');
          return const Right(null);
        }
        final payAccountDetails = payAccountDetailsModel.toEntity();
        print('💰 [REPOSITORY] Successfully retrieved pay account details for schoolId: $schoolId');
        return Right(payAccountDetails);
      } catch (e) {
        print('💰 [REPOSITORY ERROR] Failed to get pay account details: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('💰 [REPOSITORY ERROR] No internet connection');
      return const Left(ServerFailure('No internet connection'));
    }
  }
} 