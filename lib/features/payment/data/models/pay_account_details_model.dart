import '../../domain/entities/pay_account_details.dart';

class PayAccountDetailsModel extends PayAccountDetails {
  const PayAccountDetailsModel({
    required super.id,
    required super.teacherId,
    required super.slider1Url,
  });

  factory PayAccountDetailsModel.fromJson(Map<String, dynamic> json) {
    return PayAccountDetailsModel(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacherId']?.toString() ?? '',
      slider1Url: json['slider1_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teacherId': teacherId,
      'slider1_url': slider1Url,
    };
  }

  PayAccountDetails toEntity() {
    return PayAccountDetails(
      id: id,
      teacherId: teacherId,
      slider1Url: slider1Url,
    );
  }
}
