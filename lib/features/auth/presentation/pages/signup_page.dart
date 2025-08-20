import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../constants/strings.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/custom_date_picker.dart';

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
                  // Name field
                  TextField(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Enter name here',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (name) {
                      context.read<AuthBloc>().add(
                        NameChanged(name),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Birthday field
                  CustomDatePicker(
                    label: 'Select Birthday',
                    onDateSelected: (birthday) {
                      context.read<AuthBloc>().add(
                        BirthdayChanged(birthday),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // District field
                  DropdownButtonFormField<String>(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Select District',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    dropdownColor: Colors.white,
                    value: state.district.isNotEmpty ? state.district : null,
                    items: const [
                      DropdownMenuItem(value: 'Ampara', child: Text('Ampara', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Anuradhapura', child: Text('Anuradhapura', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Badulla', child: Text('Badulla', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Batticaloa', child: Text('Batticaloa', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Colombo', child: Text('Colombo', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Galle', child: Text('Galle', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Gampaha', child: Text('Gampaha', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Hambantota', child: Text('Hambantota', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Jaffna', child: Text('Jaffna', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Kalutara', child: Text('Kalutara', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Kandy', child: Text('Kandy', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Kegalle', child: Text('Kegalle', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Kilinochchi', child: Text('Kilinochchi', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Kurunegala', child: Text('Kurunegala', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Mannar', child: Text('Mannar', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Matale', child: Text('Matale', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Matara', child: Text('Matara', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Monaragala', child: Text('Monaragala', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Mullaitivu', child: Text('Mullaitivu', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Nuwara Eliya', child: Text('Nuwara Eliya', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Polonnaruwa', child: Text('Polonnaruwa', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Puttalam', child: Text('Puttalam', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Ratnapura', child: Text('Ratnapura', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Trincomalee', child: Text('Trincomalee', style: TextStyle(color: Colors.black87))),
                      DropdownMenuItem(value: 'Vavuniya', child: Text('Vavuniya', style: TextStyle(color: Colors.black87))),
                    ],
                    onChanged: (district) {
                      if (district != null) {
                        context.read<AuthBloc>().add(
                          DistrictChanged(district),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone number field (digits only, max 10)
                  TextField(
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: AppStrings.phoneNumberHint,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (phoneNumber) {
                      final trimmed = phoneNumber.trim();
                      context.read<AuthBloc>().add(
                        PhoneNumberChanged(trimmed),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Teacher ID field
                  TextField(
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Enter Teacher ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (teacherId) {
                      context.read<AuthBloc>().add(
                        TeacherIdChanged(teacherId),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextField(
                    obscureText: true,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: AppStrings.passwordHint,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (password) {
                      context.read<AuthBloc>().add(
                        PasswordChanged(password),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Confirm password field
                  TextField(
                    obscureText: true,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      labelStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: (confirmPassword) {
                      // You can add password confirmation logic here
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Sign up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == FormzStatus.submissionInProgress
                          ? null
                          : () {
                        final sanitized = state.phoneNumber.replaceAll(RegExp('\\D'), '').trim();
                        if (sanitized.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
                          );
                          return;
                        }
                        // Ensure bloc has sanitized number before submit
                        context.read<AuthBloc>().add(PhoneNumberChanged(sanitized));
                        context.read<AuthBloc>().add(const SignUpSubmitted());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state.status == FormzStatus.submissionInProgress
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.signUp),
                    ),
                  ),
                  
                  // Login link
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Already have an account? Login',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
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