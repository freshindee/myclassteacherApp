import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/sign_out.dart';
import '../../../../core/usecases.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/master_data_service.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../../home/domain/usecases/get_subjects.dart';
import '../../../home/domain/usecases/get_grades.dart';
import '../../../home/domain/usecases/get_teacher_master_data.dart';
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignIn signIn;
  final SignUp signUp;
  final SignOut signOut;
  final GetSubjects getSubjects;
  final GetGrades getGrades;
  final GetTeacherMasterData getTeacherMasterData;

  AuthBloc({
    required this.signIn,
    required this.signUp,
    required this.signOut,
    required this.getSubjects,
    required this.getGrades,
    required this.getTeacherMasterData,
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
    on<RefreshMasterData>(_onRefreshMasterData);
  }

  String? _validateTeacherId(String teacherId) {
    if (teacherId.isEmpty) {
      return 'Teacher ID is required';
    }
    if (teacherId.length != 6) {
      return 'Teacher ID must be exactly 6 digits';
    }
    if (!RegExp(r'^\d+$').hasMatch(teacherId)) {
      return 'Teacher ID must contain only numbers';
    }
    return null;
  }

  String? _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      return 'Phone number is required';
    }
    // Remove common formatting characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 9 || cleaned.length > 15) {
      return 'Please enter a valid phone number';
    }
    if (!RegExp(r'^\+?\d+$').hasMatch(cleaned)) {
      return 'Phone number must contain only numbers and optional + prefix';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Converts backend error messages to user-friendly messages
  String _getUserFriendlyErrorMessage(Failure failure) {
    final errorMessage = failure.message.toLowerCase();
    
    // Check for invalid credentials (most common login error)
    if (errorMessage.contains('invalid credentials') ||
        errorMessage.contains('invalid user data') ||
        (errorMessage.contains('exception') && errorMessage.contains('invalid credentials'))) {
      return 'The phone number, Teacher ID, or password you entered is incorrect. Please check your credentials and try again.';
    }
    
    // Check for network/connection errors
    if (errorMessage.contains('no internet connection') ||
        errorMessage.contains('network') ||
        (errorMessage.contains('connection') && !errorMessage.contains('invalid'))) {
      return 'No internet connection. Please check your network and try again.';
    }
    
    // Check for user already exists (signup error)
    if (errorMessage.contains('user already exists')) {
      return 'An account with this phone number already exists. Please sign in instead.';
    }
    
    // Check for failed to sign in with nested errors
    if (errorMessage.contains('failed to sign in')) {
      // Check if it contains invalid credentials in the nested message
      if (errorMessage.contains('invalid credentials')) {
        return 'The phone number, Teacher ID, or password you entered is incorrect. Please check your credentials and try again.';
      }
      // Generic sign-in failure
      return 'Unable to sign in. Please check your credentials and try again.';
    }
    
    // Check for timeout errors
    if (errorMessage.contains('timeout') || errorMessage.contains('timed out')) {
      return 'The request took too long. Please check your connection and try again.';
    }
    
    // Check for server errors
    if (errorMessage.contains('server error') || 
        errorMessage.contains('internal server error') ||
        errorMessage.contains('500')) {
      return 'Server error occurred. Please try again later.';
    }
    
    // Generic fallback for unknown errors
    // If the error message is too technical, show a friendly message
    if (errorMessage.contains('exception:') || 
        errorMessage.contains('error:') ||
        errorMessage.length > 100) {
      return 'Unable to sign in. Please check your credentials and try again.';
    }
    
    return 'Something went wrong. Please try again later.';
  }

  void _onPhoneNumberChanged(
      PhoneNumberChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(
      phoneNumber: event.phoneNumber,
      clearPhoneNumberError: true,
      clearErrorMessage: true,
    ));
  }

  void _onPasswordChanged(
      PasswordChanged event,
      Emitter<AuthState> emit,
      ) {
    emit(state.copyWith(
      password: event.password,
      clearPasswordError: true,
      clearErrorMessage: true,
    ));
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
    emit(state.copyWith(
      teacherId: event.teacherId,
      clearTeacherIdError: true,
      clearErrorMessage: true,
    ));
  }

  Future<void> _onSignInSubmitted(
      SignInSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    if (state.status.isSubmissionInProgress) return;

    // Validate all fields
    final teacherIdError = _validateTeacherId(state.teacherId);
    final phoneNumberError = _validatePhoneNumber(state.phoneNumber);
    final passwordError = _validatePassword(state.password);

    // If there are validation errors, emit them and return
    if (teacherIdError != null || phoneNumberError != null || passwordError != null) {
      emit(state.copyWith(
        teacherIdError: teacherIdError,
        phoneNumberError: phoneNumberError,
        passwordError: passwordError,
        status: FormzStatus.submissionFailure,
        hasSubmitted: true,
        clearErrorMessage: true,
      ));
      return;
    }

    emit(state.copyWith(
      status: FormzStatus.submissionInProgress,
      hasSubmitted: true,
      clearErrorMessage: true,
    ));

    final result = await signIn(state.phoneNumber, state.password, state.teacherId);
    await result.fold(
          (failure) async {
        emit(state.copyWith(
          status: FormzStatus.submissionFailure,
          errorMessage: _getUserFriendlyErrorMessage(failure),
        ));
      },
          (user) async {
        // Save user session
        print('🔐 AuthBloc: Sign in successful, saving user session');
        print('🔐   - userId:  [32m${user.userId} [0m');
        print('🔐   - phoneNumber: ${user.phoneNumber}');
        print('🔐   - teacherId: ${user.teacherId}');
        await UserSessionService.saveUserSession(user);
        
        // Fetch and save master data if teacherId is available
        if (user.teacherId != null && user.teacherId!.isNotEmpty) {
          try {
            print('📦 AuthBloc: Fetching master data for teacherId: ${user.teacherId}');
            
            // Save user details to master data
            await MasterDataService.saveUserDetails(user);
            
            // First, try to fetch from master_teacher collection
            final masterDataResult = await getTeacherMasterData(user.teacherId!);
            masterDataResult.fold(
              (failure) {
                print('⚠️ AuthBloc: Failed to fetch teacher master data: ${failure.message}');
                // Fallback to fetching from separate collections
                _fetchMasterDataFromSeparateCollections(user.teacherId!);
              },
              (masterData) async {
                if (masterData != null) {
                  await MasterDataService.saveTeacherMasterData(masterData);
                  print('✅ AuthBloc: Saved teacher master data (${masterData.grades.length} grades, ${masterData.subjects.length} subjects, ${masterData.teachers.length} teachers, pricing data)');
                  print('✅ AuthBloc: Grades saved: ${masterData.grades}');
                  print('✅ AuthBloc: Subjects saved: ${masterData.subjects}');
                  print('✅ AuthBloc: Teachers saved: ${masterData.teachers.length} teachers');
                  print('✅ AuthBloc: TeacherId: ${masterData.teacherId}');
                } else {
                  print('⚠️ AuthBloc: No teacher master data found, falling back to separate collections');
                  // Fallback to fetching from separate collections
                  _fetchMasterDataFromSeparateCollections(user.teacherId!);
                }
              },
            );
          } catch (e) {
            print('⚠️ AuthBloc: Error saving master data: $e');
            // Don't fail login if master data fetch fails
          }
        }
        
        emit(state.copyWith(
          status: FormzStatus.submissionSuccess,
          user: user,
          clearErrorMessage: true,
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
        
        // Fetch and save master data if teacherId is available
        if (user.teacherId != null && user.teacherId!.isNotEmpty) {
          try {
            print('📦 AuthBloc: Fetching master data for teacherId: ${user.teacherId}');
            
            // Save user details to master data
            await MasterDataService.saveUserDetails(user);
            
            // First, try to fetch from master_teacher collection
            final masterDataResult = await getTeacherMasterData(user.teacherId!);
            masterDataResult.fold(
              (failure) {
                print('⚠️ AuthBloc: Failed to fetch teacher master data: ${failure.message}');
                // Fallback to fetching from separate collections
                _fetchMasterDataFromSeparateCollections(user.teacherId!);
              },
              (masterData) async {
                if (masterData != null) {
                  await MasterDataService.saveTeacherMasterData(masterData);
                  print('✅ AuthBloc: Saved teacher master data (${masterData.grades.length} grades, ${masterData.subjects.length} subjects, ${masterData.teachers.length} teachers, pricing data)');
                  print('✅ AuthBloc: Grades saved: ${masterData.grades}');
                  print('✅ AuthBloc: Subjects saved: ${masterData.subjects}');
                  print('✅ AuthBloc: Teachers saved: ${masterData.teachers.length} teachers');
                  print('✅ AuthBloc: TeacherId: ${masterData.teacherId}');
                } else {
                  print('⚠️ AuthBloc: No teacher master data found, falling back to separate collections');
                  // Fallback to fetching from separate collections
                  _fetchMasterDataFromSeparateCollections(user.teacherId!);
                }
              },
            );
          } catch (e) {
            print('⚠️ AuthBloc: Error saving master data: $e');
            // Don't fail signup if master data fetch fails
          }
        }
        
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
        // Clear user session and master data
        await UserSessionService.clearUserSession();
        await MasterDataService.clearMasterData();
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
      
      // Check if master data needs refresh (older than 2 hours)
      if (user.teacherId != null && user.teacherId!.isNotEmpty) {
        final shouldRefresh = await MasterDataService.shouldRefreshMasterData();
        if (shouldRefresh) {
          print('🔄 AuthBloc: Master data cache is older than 2 hours, refreshing...');
          // Refresh master data in background
          _refreshMasterDataInBackground(user.teacherId!);
        } else {
          print('✅ AuthBloc: Master data cache is still fresh (less than 2 hours old)');
        }
      }
    } else {
      emit(state.copyWith(
        status: FormzStatus.pure,
        user: null,
      ));
    }
  }

  // Handler for manual refresh master data event
  Future<void> _onRefreshMasterData(
    RefreshMasterData event,
    Emitter<AuthState> emit,
  ) async {
    final user = state.user;
    if (user?.teacherId == null || user!.teacherId!.isEmpty) {
      print('⚠️ AuthBloc: Cannot refresh master data - no teacherId');
      return;
    }
    
    await _refreshMasterDataInBackground(user.teacherId!);
  }

  // Helper method to refresh master data in background
  Future<void> _refreshMasterDataInBackground(String teacherId) async {
    try {
      print('🔄 AuthBloc: Refreshing master data for teacherId: $teacherId');
      
      // Fetch fresh master data from Firebase
      final masterDataResult = await getTeacherMasterData(teacherId);
      masterDataResult.fold(
        (failure) {
          print('⚠️ AuthBloc: Failed to refresh master data: ${failure.message}');
          // Keep using cached data if refresh fails
        },
        (masterData) async {
          if (masterData != null) {
            await MasterDataService.saveTeacherMasterData(masterData);
            print('✅ AuthBloc: Refreshed master data (${masterData.grades.length} grades, ${masterData.subjects.length} subjects, ${masterData.teachers.length} teachers)');
            print('✅ AuthBloc: Bank details count: ${masterData.bankDetails.length}');
            print('✅ AuthBloc: Slider images count: ${masterData.sliderImages.length}');
          } else {
            print('⚠️ AuthBloc: No master data found during refresh');
          }
        },
      );
    } catch (e) {
      print('⚠️ AuthBloc: Error refreshing master data: $e');
      // Keep using cached data if refresh fails
    }
  }

  // Helper method to fetch master data from separate collections (fallback)
  Future<void> _fetchMasterDataFromSeparateCollections(String teacherId) async {
    // Fetch and save subjects
    final subjectsResult = await getSubjects(teacherId);
    subjectsResult.fold(
      (failure) => print('⚠️ AuthBloc: Failed to fetch subjects: ${failure.message}'),
      (subjects) async {
        await MasterDataService.saveSubjects(subjects);
        print('✅ AuthBloc: Saved ${subjects.length} subjects to master data');
      },
    );
    
    // Fetch and save grades
    final gradesResult = await getGrades(teacherId);
    gradesResult.fold(
      (failure) => print('⚠️ AuthBloc: Failed to fetch grades: ${failure.message}'),
      (grades) async {
        await MasterDataService.saveGrades(grades);
        print('✅ AuthBloc: Saved ${grades.length} grades to master data');
      },
    );
  }
}