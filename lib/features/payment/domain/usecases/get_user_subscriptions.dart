import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/subscription.dart';
import '../repositories/payment_repository.dart';

class GetUserSubscriptions
    implements UseCase<List<Subscription>, GetUserSubscriptionsParams> {
  final PaymentRepository repository;

  GetUserSubscriptions(this.repository);

  @override
  Future<Either<Failure, List<Subscription>>> call(
      GetUserSubscriptionsParams params) async {
    return await repository.getUserSubscriptions(params.userId);
  }
}

class GetUserSubscriptionsParams extends Equatable {
  final String userId;

  const GetUserSubscriptionsParams({required this.userId});

  @override
  List<Object> get props => [userId];
} 