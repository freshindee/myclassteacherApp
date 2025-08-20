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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFff5858),
              Color(0xFFf09819),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 64,
                        height: 64,
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
                              if (state.status == FormzStatus.submissionFailure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(state.errorMessage ?? 'Authentication Failed')),
                                );
                              }
                            },
                            builder: (context, state) {
                              return Column(
                                children: [
                                  TextField(
                                    controller: _teacherIdController,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.teacherIdHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.badge_outlined),
                                      filled: true,
                                      fillColor: Colors.grey[100],
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
                                    decoration: InputDecoration(
                                      labelText: AppStrings.phoneNumberHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      prefixIcon: const Icon(Icons.phone),
                                      filled: true,
                                      fillColor: Colors.grey[100],
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
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      filled: true,
                                      fillColor: Colors.grey[100],
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