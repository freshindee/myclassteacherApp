import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../models/subscription_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> createPayment(Payment payment) async {
    print('💳 [REPOSITORY] PaymentRepository.createPayment called with payment: ${payment.id}');
    
    if (await networkInfo.isConnected) {
      try {
        print('💳 [REPOSITORY] Network connected, calling remote data source...');
        await remoteDataSource.createPayment(payment);
        print('💳 [REPOSITORY] Successfully created payment with ID: ${payment.id}');
        return const Right(null);
      } catch (e) {
        print('💳 [REPOSITORY ERROR] Failed to create payment: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('💳 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasAccess(String userId, String grade, String subject, int month, int year) async {
    print('💳 [REPOSITORY] PaymentRepository.hasAccess called with userId: $userId, grade: $grade, subject: $subject, month: $month, year: $year');
    
    if (await networkInfo.isConnected) {
      try {
        print('💳 [REPOSITORY] Network connected, calling remote data source...');
        final hasAccess = await remoteDataSource.hasAccess(userId, grade, subject, month, year);
        print('💳 [REPOSITORY] Access check result: $hasAccess');
        return Right(hasAccess);
      } catch (e) {
        print('💳 [REPOSITORY ERROR] Failed to check access: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('💳 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Subscription>>> getUserSubscriptions(String userId) async {
    print('💳 [REPOSITORY] PaymentRepository.getUserSubscriptions called with userId: $userId');
    
    if (await networkInfo.isConnected) {
      try {
        print('💳 [REPOSITORY] Network connected, calling remote data source...');
        final subscriptionModels = await remoteDataSource.getUserSubscriptions(userId);
        print('💳 [REPOSITORY] Successfully fetched ${subscriptionModels.length} subscription models from remote data source');
        
        final subscriptions = subscriptionModels.map((model) => Subscription(
          id: model.id,
          userId: model.userId,
          grade: model.grade,
          subject: model.subject,
          month: model.month,
          year: model.year,
          startDate: model.startDate,
          endDate: model.endDate,
          isActive: model.isActive,
          paymentId: model.paymentId,
        )).toList();
        
        print('💳 [REPOSITORY] Successfully converted ${subscriptions.length} subscription models to entities');
        return Right(subscriptions);
      } catch (e) {
        print('💳 [REPOSITORY ERROR] Failed to fetch user subscriptions: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('💳 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getUserPayments(String userId) async {
    print('💳 [REPOSITORY] PaymentRepository.getUserPayments called with userId: $userId');
    
    if (await networkInfo.isConnected) {
      try {
        print('💳 [REPOSITORY] Network connected, calling remote data source...');
        final paymentModels = await remoteDataSource.getUserPayments(userId);
        print('💳 [REPOSITORY] Successfully fetched ${paymentModels.length} payment models from remote data source for userId: $userId');
        
        final payments = paymentModels.map((model) => Payment(
          id: model.id,
          userId: model.userId,
          grade: model.grade,
          subject: model.subject,
          month: model.month,
          year: model.year,
          amount: model.amount,
          status: model.status,
          createdAt: model.createdAt,
          completedAt: model.completedAt,
          slipUrl: model.slipUrl,
        )).toList();
        
        print('💳 [REPOSITORY] Successfully converted ${payments.length} payment models to entities for userId: $userId');
        return Right(payments);
      } catch (e) {
        print('💳 [REPOSITORY ERROR] Failed to fetch payments: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('💳 [REPOSITORY ERROR] No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 