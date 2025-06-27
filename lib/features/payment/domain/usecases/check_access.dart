import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../repositories/payment_repository.dart';

class CheckAccessParams {
  final String userId;
  final String grade;
  final String subject;
  final int month;
  final int year;

  CheckAccessParams({
    required this.userId,
    required this.grade,
    required this.subject,
    required this.month,
    required this.year,
  });
}

class CheckAccess implements UseCase<bool, CheckAccessParams> {
  final PaymentRepository repository;

  CheckAccess(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckAccessParams params) async {
    return await repository.hasAccess(
      params.userId,
      params.grade,
      params.subject,
      params.month,
      params.year,
    );
  }
} 