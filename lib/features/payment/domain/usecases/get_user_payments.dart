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
    print('🎬   - teacherId: ${params.teacherId}');
    
    return await repository.getUserPayments(params.userId, teacherId: params.teacherId);
  }
}

class GetUserPaymentsParams extends Equatable {
  final String userId;
  final String? teacherId;

  const GetUserPaymentsParams({required this.userId, this.teacherId});

  @override
  List<Object?> get props => [userId, teacherId];
} 