import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class CreatePayment implements UseCase<void, Payment> {
  final PaymentRepository repository;

  CreatePayment(this.repository);

  @override
  Future<Either<Failure, void>> call(Payment payment) async {
    return await repository.createPayment(payment);
  }
} 