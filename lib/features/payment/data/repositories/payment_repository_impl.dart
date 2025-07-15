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
    print('🎬 PaymentRepository: Creating payment with parameters:');
    print('🎬   - userId: ${payment.userId}');
    print('🎬   - grade: ${payment.grade} (grade number only)');
    print('🎬   - subject: ${payment.subject}');
    print('🎬   - month: ${payment.month}');
    print('🎬   - year: ${payment.year}');
    print('🎬   - amount: ${payment.amount}');
    print('🎬   - status: ${payment.status}');
    
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.createPayment(payment);
        print('🎬 PaymentRepository: Payment created successfully');
        return const Right(null);
      } catch (e) {
        print('❌ PaymentRepository: Failed to create payment: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('❌ PaymentRepository: No internet connection');
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
    print('🎬 PaymentRepository.getUserPayments called with parameters:');
    print('🎬   - userId: $userId');
    
    if (await networkInfo.isConnected) {
      try {
        final paymentModels = await remoteDataSource.getUserPayments(userId);
        print('🎬 PaymentRepository: Received ${paymentModels.length} payment models from data source');
        
        final payments = paymentModels.map((model) => model.toEntity()).toList();
        print('🎬 PaymentRepository: Converted ${payments.length} payment models to entities');
        
        return Right(payments);
      } catch (e) {
        print('❌ PaymentRepository: Failed to get user payments: $e');
        return Left(ServerFailure(e.toString()));
      }
    } else {
      print('❌ PaymentRepository: No internet connection');
      return Left(ServerFailure('No internet connection'));
    }
  }
} 