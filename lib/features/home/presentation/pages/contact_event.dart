part of 'contact_bloc.dart';

abstract class ContactEvent extends Equatable {
  const ContactEvent();

  @override
  List<Object> get props => [];
}

class LoadContacts extends ContactEvent {
  final String schoolId;
  const LoadContacts(this.schoolId);
  @override
  List<Object> get props => [schoolId];
} 