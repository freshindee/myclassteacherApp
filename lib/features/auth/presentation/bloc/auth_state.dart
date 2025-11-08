part of 'auth_bloc.dart';

class AuthState extends Equatable {
  final String phoneNumber;
  final String password;
  final String name;
  final DateTime? birthday;
  final String district;
  final String teacherId;
  final FormzStatus status;
  final String? errorMessage;
  final String? teacherIdError;
  final String? phoneNumberError;
  final String? passwordError;
  final User? user;
  final bool isLogout;
  final bool hasSubmitted;

  const AuthState({
    this.phoneNumber = '',
    this.password = '',
    this.name = '',
    this.birthday,
    this.district = '',
    this.teacherId = '',
    this.status = FormzStatus.pure,
    this.errorMessage,
    this.teacherIdError,
    this.phoneNumberError,
    this.passwordError,
    this.user,
    this.isLogout = false,
    this.hasSubmitted = false,
  });

  AuthState copyWith({
    String? phoneNumber,
    String? password,
    String? name,
    DateTime? birthday,
    String? district,
    String? teacherId,
    FormzStatus? status,
    String? errorMessage,
    String? teacherIdError,
    String? phoneNumberError,
    String? passwordError,
    User? user,
    bool? isLogout,
    bool? hasSubmitted,
    bool clearTeacherIdError = false,
    bool clearPhoneNumberError = false,
    bool clearPasswordError = false,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      name: name ?? this.name,
      birthday: birthday ?? this.birthday,
      district: district ?? this.district,
      teacherId: teacherId ?? this.teacherId,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      teacherIdError: clearTeacherIdError ? null : (teacherIdError ?? this.teacherIdError),
      phoneNumberError: clearPhoneNumberError ? null : (phoneNumberError ?? this.phoneNumberError),
      passwordError: clearPasswordError ? null : (passwordError ?? this.passwordError),
      user: user ?? this.user,
      isLogout: isLogout ?? this.isLogout,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
    );
  }

  @override
  List<Object?> get props => [
    phoneNumber,
    password,
    name,
    birthday,
    district,
    teacherId,
    status,
    errorMessage,
    teacherIdError,
    phoneNumberError,
    passwordError,
    user,
    isLogout,
    hasSubmitted,
  ];
}