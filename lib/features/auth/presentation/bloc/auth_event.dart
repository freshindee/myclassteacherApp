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

class NameChanged extends AuthEvent {
  final String name;

  const NameChanged(this.name);

  @override
  List<Object> get props => [name];
}

class BirthdayChanged extends AuthEvent {
  final DateTime birthday;

  const BirthdayChanged(this.birthday);

  @override
  List<Object> get props => [birthday];
}

class DistrictChanged extends AuthEvent {
  final String district;

  const DistrictChanged(this.district);

  @override
  List<Object> get props => [district];
}

class TeacherIdChanged extends AuthEvent {
  final String teacherId;

  const TeacherIdChanged(this.teacherId);

  @override
  List<Object> get props => [teacherId];
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

class RefreshMasterData extends AuthEvent {
  const RefreshMasterData();
}