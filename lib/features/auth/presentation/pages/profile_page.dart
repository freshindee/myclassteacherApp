import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/student_profile_local_service.dart';
import '../../../../core/services/student_profile_firebase_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../bloc/auth_bloc.dart';
import 'profile_page_legacy_dialogs.dart';

/// Student profile aligned with local DB / student table:
/// student_id, full_name, address, date_of_birth, district, gender, grade,
/// parent_email, parent_phone. View by default; Edit to update (saved locally + Firebase).
///
/// When [embedInHomeShell] is true, render body only (no [Scaffold] chrome) so the
/// home shell keeps the sidebar + app bar.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedInHomeShell = false});

  final bool embedInHomeShell;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const double _contentMaxWidth = 720;

  bool _editing = false;
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _profile = {};

  late TextEditingController _studentIdCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _birthdateCtrl;
  late TextEditingController _districtCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _gradeCtrl;
  late TextEditingController _parentEmailCtrl;
  late TextEditingController _parentPhoneCtrl;

  static const List<String> _sriLankaDistricts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 'Gampaha', 'Hambantota',
    'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara',
    'Monaragala', 'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 'Trincomalee', 'Vavuniya',
  ];

  static const Color _headerBlue = Color(0xFF1976D2);
  static const Color _headerBlueDeep = Color(0xFF0D47A1);

  @override
  void initState() {
    super.initState();
    _studentIdCtrl = TextEditingController();
    _fullNameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _birthdateCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _genderCtrl = TextEditingController();
    _gradeCtrl = TextEditingController();
    _parentEmailCtrl = TextEditingController();
    _parentPhoneCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _fullNameCtrl.dispose();
    _addressCtrl.dispose();
    _birthdateCtrl.dispose();
    _districtCtrl.dispose();
    _genderCtrl.dispose();
    _gradeCtrl.dispose();
    _parentEmailCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }

  void _controllersFromProfile() {
    String v(String key) => (_profile[key] ?? '').toString();
    _studentIdCtrl.text = v('student_id');
    _fullNameCtrl.text = v('full_name');
    _addressCtrl.text = v('address');
    _birthdateCtrl.text = v('date_of_birth');
    _districtCtrl.text = v('district');
    _genderCtrl.text = v('gender');
    _gradeCtrl.text = v('grade');
    _parentEmailCtrl.text = v('parent_email');
    _parentPhoneCtrl.text = v('parent_phone');
  }

  void _profileFromControllers() {
    _profile['student_id'] = _studentIdCtrl.text.trim();
    _profile['full_name'] = _fullNameCtrl.text.trim();
    _profile['address'] = _addressCtrl.text.trim();
    _profile['date_of_birth'] = _birthdateCtrl.text.trim();
    _profile['district'] = _districtCtrl.text.trim();
    _profile['gender'] = _genderCtrl.text.trim();
    _profile['grade'] = _gradeCtrl.text.trim();
    _profile['parent_email'] = _parentEmailCtrl.text.trim();
    _profile['parent_phone'] = _parentPhoneCtrl.text.trim();
  }

  Future<void> _loadProfile() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    var map = await StudentProfileLocalService.getProfile(user.userId);
    final studentDetails = await UserSessionService.getStudentDetails();
    if (studentDetails != null && studentDetails.isNotEmpty) {
      map = await StudentProfileLocalService.mergeFromStudentDetails(user.userId, studentDetails);
    }
    if (!mounted) return;
    setState(() {
      _profile = map;
      _controllersFromProfile();
      _loading = false;
    });
  }

  Future<void> _pickBirthdate() async {
    DateTime initial = DateTime.tryParse(_birthdateCtrl.text) ?? DateTime(2010, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _birthdateCtrl.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _saveLocal() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) return;
    _profileFromControllers();
    setState(() => _saving = true);
    try {
      await StudentProfileLocalService.saveProfile(user.userId, _profile);

      final schoolId = user.teacherId ?? '';
      String? documentId = (_profile['firestore_document_id'] ?? '').toString().trim();
      if (documentId.isEmpty) {
        final details = await UserSessionService.getStudentDetails();
        documentId = (details?['firestore_document_id'] ?? '').toString().trim();
      }
      if (documentId.isEmpty && _parentPhoneCtrl.text.isNotEmpty) {
        documentId = _parentPhoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      }

      if (schoolId.isNotEmpty && documentId.isNotEmpty) {
        await StudentProfileFirebaseService.updateStudentProfile(
          schoolId: schoolId,
          documentId: documentId,
          profile: _profile,
        );
        _profile['firestore_document_id'] = documentId;
        await StudentProfileLocalService.saveProfile(user.userId, _profile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved locally and to cloud')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved locally only. Re-login to sync to cloud next time.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved locally. Cloud sync failed: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _editing = false;
        });
      }
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.isNotEmpty ? s.substring(0, 1).toUpperCase() : '?';
    }
    final a = parts.first;
    final b = parts.last;
    if (a.isEmpty) return '?';
    return '${a[0]}${b.isNotEmpty ? b[0] : ''}'.toUpperCase();
  }

  void _logout() {
    context.read<AuthBloc>().add(const SignOutSubmitted());
    // Navigation to login is handled by [HomePage]'s [BlocListener] once sign-out completes
    // ([pushNamedAndRemoveUntil] clears any pushed routes such as this profile screen).
  }

  Widget _profileActions() {
    if (_loading) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          tooltip: _editing ? 'Cancel editing' : 'Edit profile',
          style: IconButton.styleFrom(foregroundColor: widget.embedInHomeShell ? _headerBlue : null),
          icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
          onPressed: () {
            setState(() {
              if (_editing) {
                _controllersFromProfile();
                _editing = false;
              } else {
                _editing = true;
              }
            });
          },
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: widget.embedInHomeShell ? _headerBlue : null),
          onSelected: (v) async {
            if (v == 'password') {
              await ProfilePageLegacyDialogs.showPasswordResetFlow(context);
            } else if (v == 'refresh') {
              if (!mounted) return;
              context.read<AuthBloc>().add(const RefreshMasterData());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refresh started')),
              );
            } else if (v == 'logout') {
              _logout();
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'password', child: Text('Reset password')),
            PopupMenuItem(value: 'refresh', child: Text('Refresh app data')),
            PopupMenuItem(value: 'logout', child: Text('Logout')),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_headerBlue, _headerBlueDeep],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'My Class Teacher',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Back to menu'),
              subtitle: const Text('Return to home grid'),
              onTap: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) Navigator.of(context).pop();
                });
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'You can reopen profile anytime from the home screen.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _headerBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildHeroHeader(String displayName, String subtitle) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_headerBlue, _headerBlueDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: _headerBlue.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.person_outline,
              size: 140,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white,
                  child: Text(
                    _initials(displayName),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName.isEmpty ? 'Student' : displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    final v = value.isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  v,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionsCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quick actions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => setState(() => _editing = true),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit profile'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await ProfilePageLegacyDialogs.showPasswordResetFlow(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Reset password'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                context.read<AuthBloc>().add(const RefreshMasterData());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refresh started')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sync_outlined),
              label: const Text('Update app data'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildView() {
    String v(String key) => (_profile[key] ?? '').toString();
    if (v('full_name').isEmpty && v('student_id').isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        children: [
          if (widget.embedInHomeShell) _profileActions(),
          _buildHeroHeader('Your profile', 'Add your details'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.cloud_off_outlined, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No profile data yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Load from your session or enter details manually.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Load from session'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Enter details'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final name = v('full_name');
    final grade = v('grade');
    final heroSubtitle = [
      if (grade.isNotEmpty) 'Grade $grade',
      if (v('student_id').isNotEmpty) 'ID: ${v('student_id')}',
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        if (widget.embedInHomeShell) _profileActions(),
        _buildHeroHeader(name.isEmpty ? 'Student' : name, heroSubtitle),
        _sectionCard(
          title: 'Student details',
          icon: Icons.school_outlined,
          children: [
            _infoTile(Icons.badge_outlined, 'Student ID', v('student_id')),
            _infoTile(Icons.person_outline, 'Full name', v('full_name')),
            _infoTile(Icons.home_work_outlined, 'Address', v('address')),
            _infoTile(Icons.cake_outlined, 'Birthdate', v('date_of_birth')),
            _infoTile(Icons.map_outlined, 'District', v('district')),
            _infoTile(Icons.wc_outlined, 'Gender', v('gender')),
            _infoTile(Icons.class_outlined, 'Grade', v('grade')),
          ],
        ),
        _sectionCard(
          title: 'Parent / guardian',
          icon: Icons.family_restroom_outlined,
          children: [
            _infoTile(Icons.email_outlined, 'Parent email', v('parent_email')),
            _infoTile(Icons.phone_iphone_outlined, 'Parent phone', v('parent_phone')),
            if ((_profile['parent_name'] ?? '').toString().isNotEmpty)
              _infoTile(Icons.person_pin_outlined, 'Parent name', v('parent_name')),
            if ((_profile['status'] ?? '').toString().isNotEmpty)
              _infoTile(Icons.flag_outlined, 'Status', v('status')),
          ],
        ),
        _quickActionsCard(),
      ],
    );
  }

  Widget _buildEditForm() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        if (widget.embedInHomeShell) _profileActions(),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Changes are saved on this device and synced when possible.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                InputDecorator(
                  decoration: _fieldDecoration('Student ID', helper: 'Not editable'),
                  child: Text(
                    _studentIdCtrl.text.isEmpty ? '—' : _studentIdCtrl.text,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _fullNameCtrl,
                  decoration: _fieldDecoration('Full name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: _fieldDecoration('Address'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickBirthdate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: _fieldDecoration('Birthdate'),
                    child: Text(_birthdateCtrl.text.isEmpty ? 'Tap to select' : _birthdateCtrl.text),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _districtCtrl.text.isEmpty
                      ? null
                      : (_sriLankaDistricts.contains(_districtCtrl.text) ? _districtCtrl.text : null),
                  decoration: _fieldDecoration('District'),
                  hint: Text(_districtCtrl.text.isEmpty ? 'Select district' : _districtCtrl.text),
                  items: _sriLankaDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) => setState(() => _districtCtrl.text = val ?? ''),
                ),
                const SizedBox(height: 14),
                TextField(controller: _genderCtrl, decoration: _fieldDecoration('Gender')),
                const SizedBox(height: 14),
                TextField(controller: _gradeCtrl, decoration: _fieldDecoration('Grade')),
                const SizedBox(height: 14),
                TextField(
                  controller: _parentEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration('Parent email'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _parentPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration('Parent phone'),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _controllersFromProfile();
                          setState(() => _editing = false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saving ? null : _saveLocal,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bodyContent() {
    final user = context.watch<AuthBloc>().state.user;
    if (user == null) {
      return const Center(child: Text('No user loaded'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: _editing ? _buildEditForm() : _buildView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _bodyContent();

    if (widget.embedInHomeShell) {
      return content;
    }

    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: _headerBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          if (!_loading && user != null) ...[
            IconButton(
              tooltip: _editing ? 'Cancel' : 'Edit',
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  if (_editing) {
                    _controllersFromProfile();
                    _editing = false;
                  } else {
                    _editing = true;
                  }
                });
              },
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'password') {
                  await ProfilePageLegacyDialogs.showPasswordResetFlow(context);
                } else if (v == 'refresh') {
                  if (!mounted) return;
                  context.read<AuthBloc>().add(const RefreshMasterData());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Refresh started')),
                  );
                } else if (v == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'password', child: Text('Reset password')),
                PopupMenuItem(value: 'refresh', child: Text('Refresh app data')),
                PopupMenuItem(value: 'logout', child: Text('Logout')),
              ],
            ),
          ],
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: content,
      ),
    );
  }
}
