part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final String phoneNumber;
  final String password;
  final FormzStatus status;
  final String? errorMessage;
  final User? user;
  final bool isLogout;

  const AuthState({
    this.phoneNumber = '',
    this.password = '',
    this.status = FormzStatus.pure,
    this.errorMessage,
    this.user,
    this.isLogout = false,
  });

  AuthState copyWith({
    String? phoneNumber,
    String? password,
    FormzStatus? status,
    String? errorMessage,
    User? user,
    bool? isLogout,
  }) {
    return AuthState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      isLogout: isLogout ?? this.isLogout,
    );
  }

  @override
  List<Object?> get props => [phoneNumber, password, status, errorMessage, user, isLogout];
}