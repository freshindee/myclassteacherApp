import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateUser {
  final AuthRepository repository;

  UpdateUser(this.repository);

  Future<Either<Failure, User>> call({
    required String userId,
    String? phoneNumber,
    String? name,
    DateTime? birthday,
    String? district,
    String? newPassword,
  }) async {
    return repository.updateUser(
      userId: userId,
      phoneNumber: phoneNumber,
      name: name,
      birthday: birthday,
      district: district,
      newPassword: newPassword,
    );
  }
}


