import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../injection_container.dart';
import '../../../../core/services/user_session_service.dart';
import '../bloc/auth_bloc.dart';

/// Password reset + dialogs extracted from legacy profile page.
class ProfilePageLegacyDialogs {
  static Future<void> showPasswordResetFlow(BuildContext context) async {
    final ok = await _showResetCodeDialog(context);
    if (ok != true || !context.mounted) return;
    await _showNewPasswordDialog(context);
  }

  static Future<bool?> _showResetCodeDialog(BuildContext context) async {
    final TextEditingController codeCtrl = TextEditingController();
    String? errorText;
    bool submitting = false;
    final currentUser = context.read<AuthBloc>().state.user;
    final schoolId = currentUser?.teacherId ?? '';

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              title: const Text('Enter Reset Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter reset code',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final code = codeCtrl.text.trim();
                          if (code.isEmpty) {
                            setLocalState(() => errorText = 'Reset code is required');
                            return;
                          }
                          if (schoolId.isEmpty) {
                            setLocalState(() => errorText = 'School not found. Please login again.');
                            return;
                          }

                          setLocalState(() {
                            submitting = true;
                            errorText = null;
                          });

                          try {
                            final appConfigSnap = await FirebaseFirestore.instance
                                .collection('schools')
                                .doc(schoolId)
                                .collection('app_config')
                                .limit(1)
                                .get();
                            if (appConfigSnap.docs.isEmpty) {
                              setLocalState(() => errorText = 'Reset code not configured for this school.');
                              return;
                            }
                            final storedCode = appConfigSnap.docs.first
                                .data()['password_reset_code']
                                ?.toString()
                                .trim();
                            if (storedCode == null || storedCode.isEmpty || storedCode != code) {
                              setLocalState(() => errorText = 'Invalid reset code');
                              return;
                            }
                            Navigator.of(ctx).pop(true);
                          } catch (e) {
                            setLocalState(() => errorText = 'Failed to verify reset code. Please try again.');
                          } finally {
                            setLocalState(() => submitting = false);
                          }
                        },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static Future<void> _showNewPasswordDialog(BuildContext context) async {
    final current = context.read<AuthBloc>().state.user;
    if (current == null) return;
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorText;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            Future<void> submit() async {
              final p1 = passCtrl.text;
              final p2 = confirmCtrl.text;
              if (p1.isEmpty || p2.isEmpty) {
                setLocalState(() => errorText = 'Password fields cannot be empty');
                return;
              }
              if (p1 != p2) {
                setLocalState(() => errorText = 'Passwords do not match');
                return;
              }
              final schoolId = current.teacherId ?? '';
              if (schoolId.isEmpty) {
                setLocalState(() => errorText = 'School not found. Please login again.');
                return;
              }

              // Determine student document id from stored student details
              final details = await UserSessionService.getStudentDetails();
              String documentId = (details?['firestore_document_id'] ?? '').toString().trim();
              if (documentId.isEmpty) {
                documentId = (details?['student_id'] ?? '').toString().trim();
              }
              if (documentId.isEmpty) {
                final parentPhone = (details?['parent_phone'] ?? '').toString();
                if (parentPhone.isNotEmpty) {
                  documentId = parentPhone.replaceAll(RegExp(r'\D'), '');
                }
              }
              if (documentId.isEmpty) {
                setLocalState(() => errorText = 'Cannot find student record. Please login again.');
                return;
              }

              setLocalState(() {
                submitting = true;
                errorText = null;
              });
              try {
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(schoolId)
                    .collection('students')
                    .doc(documentId)
                    .update({'password': p1});

                if (!context.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password has been reset')),
                );
              } catch (e) {
                setLocalState(() {
                  submitting = false;
                  errorText = 'Something went wrong. Please try again';
                });
              }
            }

            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'New password'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
