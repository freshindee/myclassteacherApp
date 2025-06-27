part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class EmailChanged extends AuthEvent {
  final String email;

  const EmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class PasswordChanged extends AuthEvent {
  final String password;

  const PasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class SignInSubmitted extends AuthEvent {
  const SignInSubmitted();
}

class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted();
}

class SignOutSubmitted extends AuthEvent {
  const SignOutSubmitted();
}