import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/sign_in_student_result.dart';
import '../repositories/auth_repository.dart';

class SignInStudent {
  final AuthRepository repository;

  SignInStudent(this.repository);

  Future<Either<Failure, SignInStudentResult>> call(String schoolId, String username, String password) async {
    return await repository.signInStudent(schoolId, username, password);
  }
}
