import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../constants/strings.dart';
import '../bloc/auth_bloc.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              // Navigate to home page
              Navigator.of(context).pushReplacementNamed('/home');
            }
            if (state.status == FormzStatus.submissionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Registration Failed')),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: AppStrings.emailHint,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (email) {
                      context.read<AuthBloc>().add(
                        EmailChanged(email),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.passwordHint,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (password) {
                      context.read<AuthBloc>().add(
                        PasswordChanged(password),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (confirmPassword) {
                      // You can add password confirmation logic here
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == FormzStatus.submissionInProgress
                          ? null
                          : () {
                        context.read<AuthBloc>().add(
                          const SignUpSubmitted(),
                        );
                      },
                      child: state.status == FormzStatus.submissionInProgress
                          ? const CircularProgressIndicator()
                          : const Text(AppStrings.signUp),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Already have an account? Login',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 