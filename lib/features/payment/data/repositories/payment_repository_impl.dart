import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/subscription_model.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
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
      return Left(ServerFailure('No internet connection'));
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
      return Left(ServerFailure('No internet connection'));
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
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getUserPayments(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final paymentModels = await remoteDataSource.getUserPayments(userId);
        final payments = paymentModels.map((model) => model.toEntity()).toList();
        return Right(payments);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection'));
    }
  }
} 