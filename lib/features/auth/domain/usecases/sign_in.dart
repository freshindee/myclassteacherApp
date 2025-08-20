import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignIn {
  final AuthRepository repository;

  SignIn(this.repository);

  Future<Either<Failure, User>> call(String phoneNumber, String password, String teacherId) async {
    return await repository.signIn(phoneNumber, password, teacherId);
  }
}