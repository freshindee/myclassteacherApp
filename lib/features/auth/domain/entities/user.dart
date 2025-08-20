import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String userId;
  final String phoneNumber;
  final String password;
  final String? name;
  final DateTime? birthday;
  final String? district;
  final String? teacherId;

  const User({
    required this.userId,
    required this.phoneNumber,
    required this.password,
    this.name,
    this.birthday,
    this.district,
    this.teacherId,
  });

  @override
  List<Object?> get props => [userId, phoneNumber, password, name, birthday, district, teacherId];
}