import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/contact.dart';
import '../../domain/usecases/get_contacts.dart';
import '../../../../core/usecases.dart';

part 'contact_event.dart';
part 'contact_state.dart';

class ContactBloc extends Bloc<ContactEvent, ContactState> {
  final GetContacts getContacts;

  ContactBloc({required this.getContacts}) : super(ContactInitial()) {
    on<LoadContacts>(_onLoadContacts);
  }

  Future<void> _onLoadContacts(
    LoadContacts event,
    Emitter<ContactState> emit,
  ) async {
    emit(ContactLoading());
    final result = await getContacts(event.teacherId);
    result.fold(
      (failure) => emit(ContactError(failure.toString())),
      (contacts) => emit(ContactLoaded(contacts)),
    );
  }
} 