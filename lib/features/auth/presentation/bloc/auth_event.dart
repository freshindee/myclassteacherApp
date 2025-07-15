part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class PhoneNumberChanged extends AuthEvent {
  final String phoneNumber;

  const PhoneNumberChanged(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
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

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}