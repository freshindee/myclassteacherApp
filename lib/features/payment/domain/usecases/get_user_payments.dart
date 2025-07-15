import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetUserPayments
    implements UseCase<List<Payment>, GetUserPaymentsParams> {
  final PaymentRepository repository;

  GetUserPayments(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(
      GetUserPaymentsParams params) async {
    print('🎬 GetUserPayments usecase called with parameters:');
    print('🎬   - userId: ${params.userId}');
    
    return await repository.getUserPayments(params.userId);
  }
}

class GetUserPaymentsParams extends Equatable {
  final String userId;

  const GetUserPaymentsParams({required this.userId});

  @override
  List<Object> get props => [userId];
} 