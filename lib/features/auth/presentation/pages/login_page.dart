import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../constants/strings.dart';
import '../bloc/auth_bloc.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _phoneNumberController;
  late TextEditingController _passwordController;
  late TextEditingController _teacherIdController;
  String? _lastErrorMessage;
  bool _hasShownError = false;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
    _teacherIdController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color:Colors.white,
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const SizedBox(height: 70),
                  // Logo/Icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(1),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.appName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFff5858),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          BlocConsumer<AuthBloc, AuthState>(
                            listener: (context, state) {
                              if (state.status == FormzStatus.submissionSuccess) {
                                Navigator.of(context).pushReplacementNamed('/home');
                              }
                              // Only show SnackBar for server/authentication errors, not validation errors
                              // And only show it once per unique error message
                              if (state.status == FormzStatus.submissionFailure &&
                                  state.errorMessage != null &&
                                  state.errorMessage != _lastErrorMessage &&
                                  !_hasShownError) {
                                _lastErrorMessage = state.errorMessage;
                                _hasShownError = true;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(state.errorMessage!),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                                // Reset flag after a delay to allow showing new errors
                                Future.delayed(const Duration(seconds: 5), () {
                                  if (mounted) {
                                    _hasShownError = false;
                                  }
                                });
                              }
                              // Reset flag when error message changes
                              if (state.errorMessage != _lastErrorMessage) {
                                _lastErrorMessage = state.errorMessage;
                                _hasShownError = false;
                              }
                            },
                            builder: (context, state) {
                              return Column(
                                children: [
                                  TextField(
                                    controller: _teacherIdController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.teacherIdHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.teacherIdError != null
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.teacherIdError != null
                                              ? Colors.red
                                              : const Color(0xFFff5858),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.badge_outlined),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      errorText: state.hasSubmitted ? state.teacherIdError : null,
                                      errorMaxLines: 2,
                                    ),
                                    onChanged: (teacherId) {
                                      context.read<AuthBloc>().add(
                                        TeacherIdChanged(teacherId),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _phoneNumberController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.phoneNumberHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.phoneNumberError != null
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.phoneNumberError != null
                                              ? Colors.red
                                              : const Color(0xFFff5858),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.phone),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      errorText: state.hasSubmitted ? state.phoneNumberError : null,
                                      errorMaxLines: 2,
                                    ),
                                    onChanged: (phoneNumber) {
                                      context.read<AuthBloc>().add(
                                        PhoneNumberChanged(phoneNumber),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.passwordHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.passwordError != null
                                              ? Colors.red
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: state.hasSubmitted && state.passwordError != null
                                              ? Colors.red
                                              : const Color(0xFFff5858),
                                          width: 2,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.red, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      errorText: state.hasSubmitted ? state.passwordError : null,
                                      errorMaxLines: 2,
                                    ),
                                    onChanged: (password) {
                                      context.read<AuthBloc>().add(
                                        PasswordChanged(password),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: state.status == FormzStatus.submissionInProgress
                                          ? null
                                          : () {
                                              context.read<AuthBloc>().add(
                                                const SignInSubmitted(),
                                              );
                                            },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFff5858),
                                              Color(0xFFf09819),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: state.status == FormzStatus.submissionInProgress
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Text(
                                                  AppStrings.login,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const SignupPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      AppStrings.noAccount + AppStrings.signUp,
                                      style: const TextStyle(
                                        color: Color(0xFFff5858),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}