import 'user_model.dart';

/// Data-layer result of student sign-in: user model + raw student document for local storage.
class SignInStudentResultModel {
  final UserModel user;
  final Map<String, dynamic> studentDetails;

  const SignInStudentResultModel({
    required this.user,
    required this.studentDetails,
  });
}
