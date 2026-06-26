import 'package:equatable/equatable.dart';
import 'user.dart';

/// Result of successful student login: user (with schoolId as teacherId) + full student details for local use.
class SignInStudentResult extends Equatable {
  final User user;
  final Map<String, dynamic> studentDetails;

  const SignInStudentResult({
    required this.user,
    required this.studentDetails,
  });

  @override
  List<Object?> get props => [user, studentDetails];
}
