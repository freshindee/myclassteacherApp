import 'package:equatable/equatable.dart';

class PayAccountDetails extends Equatable {
  final String id;
  final String teacherId;
  final String slider1Url;

  const PayAccountDetails({
    required this.id,
    required this.teacherId,
    required this.slider1Url,
  });

  @override
  List<Object?> get props => [id, teacherId, slider1Url];
}
