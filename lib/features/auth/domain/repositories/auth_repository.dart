import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String phoneNumber, String password, String teacherId);
  Future<Either<Failure, User>> signUp(
    String phoneNumber, 
    String password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
  );
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, User>> updateUser({
    required String userId,
    String? phoneNumber,
    String? name,
    DateTime? birthday,
    String? district,
    String? newPassword,
  });
}