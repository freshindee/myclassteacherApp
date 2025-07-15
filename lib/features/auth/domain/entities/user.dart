import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String userId;
  final String phoneNumber;
  final String password;

  const User({
    required this.userId,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [userId, phoneNumber, password];
}