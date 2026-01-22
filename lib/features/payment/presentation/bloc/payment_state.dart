part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {}

class PaymentFailure extends PaymentState {
  final String message;

  const PaymentFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AccessChecked extends PaymentState {
  final bool hasAccess;

  const AccessChecked(this.hasAccess);

  @override
  List<Object> get props => [hasAccess];
}

class PayAccountDetailsLoading extends PaymentState {}

class PayAccountDetailsLoaded extends PaymentState {
  final List<String> bankDetailImages;

  const PayAccountDetailsLoaded(this.bankDetailImages);

  @override
  List<Object> get props => [bankDetailImages];
}

class PayAccountDetailsError extends PaymentState {
  final String message;

  const PayAccountDetailsError(this.message);

  @override
  List<Object> get props => [message];
} 