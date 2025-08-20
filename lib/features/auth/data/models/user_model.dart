import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String userId;
  final String phoneNumber;
  final String password;
  final String? name;
  final DateTime? birthday;
  final String? district;
  final String? teacherId;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
      district: json['district'] as String?,
      teacherId: json['teacherId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': userId,
      'phoneNumber': phoneNumber,
      'password': password,
      'name': name,
      'birthday': birthday?.toIso8601String(),
      'district': district,
      'teacherId': teacherId,
    };
  }
}