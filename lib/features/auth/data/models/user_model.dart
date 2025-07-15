import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String phoneNumber;
  final String password;

  const UserModel({
    required this.userId,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object> get props => [userId, phoneNumber, password];

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }
}