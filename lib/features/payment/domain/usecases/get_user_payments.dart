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
    print('🎬   - schoolId: ${params.schoolId}');
    
    return await repository.getUserPayments(params.userId, schoolId: params.schoolId);
  }
}

class GetUserPaymentsParams extends Equatable {
  final String userId;
  final String? schoolId;

  const GetUserPaymentsParams({required this.userId, this.schoolId});

  @override
  List<Object?> get props => [userId, schoolId];
} 