import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_out.dart';
import '../../../../core/usecases.dart';
import '../../../../core/services/user_session_service.dart';
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
    on<PhoneNumberChanged>(_onPhoneNumberChanged);
    on<PasswordChanged>(_onPasswordChanged);
    on<NameChanged>(_onNameChanged);
    on<BirthdayChanged>(_onBirthdayChanged);
    on<DistrictChanged>(_onDistrictChanged);
    on<SignInSubmitted>(_onSignInSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<SignOutSubmitted>(_onSignOutSubmitted);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<TeacherIdChanged>(_onTeacherIdChanged);
  }

  void _onPhoneNumberChanged(
      PhoneNumberChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(phoneNumber: event.phoneNumber));
  }

  void _onPasswordChanged(
      PasswordChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(password: event.password));
  }

  void _onNameChanged(
      NameChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(name: event.name));
  }

  void _onBirthdayChanged(
      BirthdayChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(birthday: event.birthday));
  }

  void _onDistrictChanged(
      DistrictChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(district: event.district));
  }

  void _onTeacherIdChanged(
      TeacherIdChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(teacherId: event.teacherId));
  }

  Future<void> _onSignInSubmitted(
      SignInSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;
    if (state.teacherId.length != 6) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        errorMessage: 'Teacher ID must be 6 digits',
      ));
      return;
    }
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    final result = await signIn(state.phoneNumber, state.password, state.teacherId);
    await result.fold(
          (failure) async {
        emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          errorMessage: failure.message,
        ));
      },
          (user) async {
        // Save user session
        print('🔐 AuthBloc: Sign in successful, saving user session');
        print('🔐   - userId:  [32m${user.userId} [0m');
        print('🔐   - phoneNumber: ${user.phoneNumber}');
        print('🔐   - teacherId: ${user.teacherId}');
        await UserSessionService.saveUserSession(user);
        emit(state.copyWith(
          status: FormzStatus.submissionSuccess,
          user: user,
        ));
      },
    );
  }

  Future<void> _onSignUpSubmitted(
      SignUpSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final result = await signUp(
      state.phoneNumber, 
      state.password,
      state.name,
      state.birthday,
      state.district,
      state.teacherId,
    );

    await result.fold(
          (failure) async {
        emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          errorMessage: failure.message,
        ));
      },
          (user) async {
        // Save user session
        await UserSessionService.saveUserSession(user);
        emit(state.copyWith(
          status: FormzStatus.submissionSuccess,
          user: user,
        ));
      },
    );
  }

  Future<void> _onSignOutSubmitted(
      SignOutSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final result = await signOut(const NoParams());

    await result.fold(
          (failure) async {
        emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          errorMessage: failure.message,
          isLogout: false,
        ));
      },
          (_) async {
        // Clear user session
        await UserSessionService.clearUserSession();
        emit(const AuthState(isLogout: true));
      },
    );
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event,
      Emitter<AuthState> emit,
      ) async {
    final user = await UserSessionService.getCurrentUser();
    if (user != null) {
      emit(state.copyWith(
        status: FormzStatus.submissionSuccess,
        user: user,
      ));
    } else {
      emit(state.copyWith(
        status: FormzStatus.pure,
        user: null,
      ));
    }
  }
}