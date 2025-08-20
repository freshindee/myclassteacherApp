import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignUp {
  final AuthRepository repository;

  SignUp(this.repository);

  Future<Either<Failure, User>> call(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
  ) async {
    return await repository.signUp(phoneNumber, password, name, birthday, district, teacherId);
  }
}