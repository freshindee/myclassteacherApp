import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String phoneNumber, String password);
  Future<Either<Failure, User>> signUp(String phoneNumber, String password);
  Future<Either<Failure, void>> signOut();
}