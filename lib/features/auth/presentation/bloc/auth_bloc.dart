import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_out.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases.dart';
import '../../domain/entities/user.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
  }) : super(const AuthState()) {
    on<EmailChanged>(_onEmailChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<SignInSubmitted>(_onSignInSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<SignOutSubmitted>(_onSignOutSubmitted);
  }

  void _onEmailChanged(
      EmailChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(email: event.email));
  }

  void _onPasswordChanged(
      PasswordChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(password: event.password));
  }

  Future<void> _onSignInSubmitted(
      SignInSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final result = await signIn(state.email, state.password);

    result.fold(
          (failure) => emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        errorMessage: failure.message,
      )),
          (user) => emit(state.copyWith(
        status: FormzStatus.submissionSuccess,
        user: user,
      )),
    );
  }

  Future<void> _onSignUpSubmitted(
      SignUpSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final result = await signUp(state.email, state.password);

    result.fold(
          (failure) => emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        errorMessage: failure.message,
      )),
          (user) => emit(state.copyWith(
        status: FormzStatus.submissionSuccess,
        user: user,
      )),
    );
  }

  Future<void> _onSignOutSubmitted(
      SignOutSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final result = await signOut(const NoParams());

    result.fold(
          (failure) => emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        errorMessage: failure.message,
      )),
          (_) => emit(state.copyWith(
        status: FormzStatus.submissionSuccess,
        user: null,
      )),
    );
  }
}