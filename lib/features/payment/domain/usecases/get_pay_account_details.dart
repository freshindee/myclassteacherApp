import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/pay_account_details.dart';
import '../repositories/payment_repository.dart';

class GetPayAccountDetails implements UseCase<PayAccountDetails?, String> {
  final PaymentRepository repository;

  GetPayAccountDetails(this.repository);

  @override
  Future<Either<Failure, PayAccountDetails?>> call(String teacherId) async {
    return await repository.getPayAccountDetails(teacherId);
  }
}
