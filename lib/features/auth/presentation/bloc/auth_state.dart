part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final String email;
  final String password;
  final FormzStatus status;
  final String? errorMessage;
  final User? user;

  const AuthState({
    this.email = '',
    this.password = '',
    this.status = FormzStatus.pure,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    String? email,
    String? password,
    FormzStatus? status,
    String? errorMessage,
    User? user,
  }) {
    return AuthState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [email, password, status, errorMessage, user];
}