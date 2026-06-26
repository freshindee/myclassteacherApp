import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/sri_lanka_phone_utils.dart';

/// Dialog to reset a student's password using a code from app_config.
/// Paths: schools/{schoolId}/app_config (password_reset_code), schools/{schoolId}/students/{studentId} (password).
class ResetPasswordDialog extends StatefulWidget {
  final String? initialSchoolId;
  final String? initialPhone;

  const ResetPasswordDialog({
    super.key,
    this.initialSchoolId,
    this.initialPhone,
  });

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  static const Color _primaryBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _schoolIdController.text = widget.initialSchoolId ?? '';
    _phoneController.text = widget.initialPhone ?? '';
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    final schoolId = _schoolIdController.text.trim();
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (schoolId.isEmpty) {
      _showSnackBar('Please enter Teacher ID / Institute ID.', Colors.orange);
      return;
    }
    if (phone.isEmpty) {
      _showSnackBar('Please enter phone number.', Colors.orange);
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar('New password and re-enter password do not match.', Colors.orange);
      return;
    }
    if (newPassword.isEmpty) {
      _showSnackBar('Please enter a new password.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final appConfigRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('app_config');
      final appConfigSnap = await appConfigRef.get();
      if (appConfigSnap.docs.isEmpty) {
        _showSnackBar('Invalid school ID or app config not found.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      final storedCode = appConfigSnap.docs.first.data()['password_reset_code']?.toString().trim();
      if (storedCode == null || storedCode.isEmpty) {
        _showSnackBar('Password reset is not configured for this school.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }
      if (code != storedCode) {
        _showSnackBar('Incorrect password reset code.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      final local = SriLankaPhoneUtils.normalizeToLocalTenDigits(phone);
      if (local == null) {
        _showSnackBar(
          SriLankaPhoneUtils.validateMobileField(phone) ??
              'Please enter a valid Sri Lanka mobile number.',
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      final studentsRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students');
      String? updatedId;
      for (final documentId in SriLankaPhoneUtils.candidateStudentDocumentIds(local)) {
        final ref = studentsRef.doc(documentId);
        final snap = await ref.get();
        if (snap.exists) {
          await ref.update({'password': newPassword});
          updatedId = documentId;
          break;
        }
      }
      if (updatedId == null) {
        _showSnackBar('No student found for this mobile number.', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      _showSnackBar('Password updated successfully. You can now login.', Colors.green);
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnackBar('Failed to reset password: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _schoolIdController,
                  decoration: const InputDecoration(
                    labelText: 'Teacher ID / Institute ID',
                    hintText: 'e.g. 123456',
                    prefixIcon: Icon(Icons.school, color: _primaryBlue),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Parent mobile (Sri Lanka)',
                    hintText: 'e.g. 0771234567 or +94 77 123 4567',
                    prefixIcon: Icon(Icons.phone, color: _primaryBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => SriLankaPhoneUtils.validateMobileField(v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Password change code',
                    hintText: 'Enter the code from your school',
                    prefixIcon: Icon(Icons.vpn_key, color: _primaryBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Code is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    hintText: 'Enter new password',
                    prefixIcon: Icon(Icons.lock_outline, color: _primaryBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'New password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Re-enter password',
                    hintText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline, color: _primaryBlue),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please re-enter password';
                    if (v != _newPasswordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
