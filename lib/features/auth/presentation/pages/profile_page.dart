import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/update_user.dart';
import '../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/services/crypto_service.dart';
import '../../../../core/services/user_session_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _districtController;
  DateTime? _birthday;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;
  static const List<String> _sriLankaDistricts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha', 'Hambantota',
    'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara',
    'Monaragala', 'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _districtController = TextEditingController(text: user?.district ?? '');
    _birthday = user?.birthday;
    _loadFreshProfileFromDb();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final initial = _birthday ?? DateTime(2005, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _loadFreshProfileFromDb() async {
    final current = context.read<AuthBloc>().state.user;
    if (current == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final crypto = sl<CryptoService>();

      DocumentReference<Map<String, dynamic>> userRef = firestore.collection('users').doc(current.userId);
      var snap = await userRef.get();
      if (!snap.exists) {
        final byUserId = await firestore
            .collection('users')
            .where('userId', isEqualTo: current.userId)
            .limit(1)
            .get();
        if (byUserId.docs.isNotEmpty) {
          userRef = byUserId.docs.first.reference;
          snap = await userRef.get();
        } else {
          final byPhone = await firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: current.userId)
              .limit(1)
              .get();
          if (byPhone.docs.isNotEmpty) {
            userRef = byPhone.docs.first.reference;
            snap = await userRef.get();
          }
        }
      }

      final data = snap.data() ?? {};
      String? name = data['name'];
      String? district = data['district'];
      DateTime? birthday;
      if (data['birthday'] != null) {
        birthday = DateTime.tryParse(data['birthday']);
      }

      try {
        if (data['nameEnc'] != null && data['nameNonce'] != null && data['nameMac'] != null) {
          name = await crypto.decryptField(
            ciphertextBase64: data['nameEnc'],
            nonceBase64: data['nameNonce'],
            macBase64: data['nameMac'],
          );
        }
        if (data['districtEnc'] != null && data['districtNonce'] != null && data['districtMac'] != null) {
          district = await crypto.decryptField(
            ciphertextBase64: data['districtEnc'],
            nonceBase64: data['districtNonce'],
            macBase64: data['districtMac'],
          );
        }
        if (data['birthdayEnc'] != null && data['birthdayNonce'] != null && data['birthdayMac'] != null) {
          final bdayStr = await crypto.decryptField(
            ciphertextBase64: data['birthdayEnc'],
            nonceBase64: data['birthdayNonce'],
            macBase64: data['birthdayMac'],
          );
          birthday = DateTime.tryParse(bdayStr);
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        if (name != null) _nameController.text = name;
        if (district != null) _districtController.text = district;
        _birthday = birthday ?? _birthday;
      });
    } catch (_) {}
  }

  Future<void> _requestPasswordReset() async {
    // Step 1: Ask for reset code
    final bool ok = await _showResetCodeDialog();
    if (!ok || !mounted) return;
    // Step 2: Ask for new password + confirm and perform reset
    await _showNewPasswordDialog();
  }

  Future<bool> _showResetCodeDialog() async {
    final TextEditingController codeCtrl = TextEditingController();
    String? errorText;
    final result = await showDialog<bool>(
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
                  onPressed: () {
                    final code = codeCtrl.text.trim();
                    if (code != '19822012') {
                      setLocalState(() {
                        errorText = 'Invalid reset code';
                      });
                      return;
                    }
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
    return result == true;
  }

  Future<void> _showNewPasswordDialog() async {
    final current = context.read<AuthBloc>().state.user;
    if (current == null) return;
    final TextEditingController passCtrl = TextEditingController();
    final TextEditingController confirmCtrl = TextEditingController();
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
              setLocalState(() {
                submitting = true;
                errorText = null;
              });
              try {
                final updateUser = sl<UpdateUser>();
                final res = await updateUser(
                  userId: current.userId,
                  newPassword: p1,
                );
                if (!mounted) return;
                await res.fold(
                  (failure) async {
                    setLocalState(() {
                      submitting = false;
                      errorText = failure.message ?? 'Failed to reset password';
                    });
                  },
                  (user) async {
                    await UserSessionService.saveUserSession(user);
                    if (!mounted) return;
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password has been reset')),
                    );
                  },
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

  bool _refreshing = false;

  Future<void> _refreshMasterData() async {
    final user = context.read<AuthBloc>().state.user;
    if (user?.teacherId == null || user!.teacherId!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot refresh: No teacher ID found'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _refreshing = true);

    // Trigger refresh master data event
    context.read<AuthBloc>().add(const RefreshMasterData());

    // Wait a bit for the refresh to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _refreshing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App data refreshed successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final current = context.read<AuthBloc>().state.user;
    if (current == null) return;
    setState(() => _saving = true);
    final updateUser = sl<UpdateUser>();
    final result = await updateUser(
      userId: current.userId,
      phoneNumber: _phoneController.text.trim(),
      name: _nameController.text.trim(),
      birthday: _birthday,
      district: _districtController.text.trim(),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message ?? 'Failed to update profile')),
        );
      },
      (user) async {
        await UserSessionService.saveUserSession(user);
        context.read<AuthBloc>().add(const CheckAuthStatus());
        if (!mounted) return;
        setState(() {
          _nameController.text = user.name ?? _nameController.text;
          _districtController.text = user.district ?? _districtController.text;
          _birthday = user.birthday ?? _birthday;
        });
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: Text('No user loaded'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickBirthday,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Birthday',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _birthday != null ? _birthday!.toIso8601String().split('T').first : 'Tap to select',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _districtController.text.isNotEmpty ? _districtController.text : null,
                      decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder()),
                      items: _sriLankaDistricts
                          .map((d) => DropdownMenuItem<String>(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _districtController.text = val);
                      },
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'District is required' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update Profile'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _saving ? null : _requestPasswordReset,
                        child: const Text('Request Password Reset'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: (_saving || _refreshing) ? null : _refreshMasterData,
                        icon: _refreshing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh, size: 20),
                        label: Text(_refreshing ? 'Refreshing...' : 'Refresh the app'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: _saving
                            ? null
                            : () {
                                context.read<AuthBloc>().add(const SignOutSubmitted());
                                Navigator.of(context).pop();
                              },
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}


