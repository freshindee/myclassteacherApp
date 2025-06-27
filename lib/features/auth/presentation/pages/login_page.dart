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
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'indika@gmail.com');
    _passwordController = TextEditingController(text: 'asdf1234');
    
    // Initialize the auth bloc with default values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(EmailChanged('indika@gmail.com'));
      context.read<AuthBloc>().add(PasswordChanged('asdf1234'));
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
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
                SnackBar(content: Text(state.errorMessage ?? 'Authentication Failed')),
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
                    controller: _emailController,
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
                    controller: _passwordController,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == FormzStatus.submissionInProgress
                          ? null
                          : () {
                        context.read<AuthBloc>().add(
                          const SignInSubmitted(),
                        );
                      },
                      child: state.status == FormzStatus.submissionInProgress
                          ? const CircularProgressIndicator()
                          : const Text(AppStrings.login),
                    ),
                  ),
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