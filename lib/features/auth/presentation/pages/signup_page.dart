import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/services/school_validation_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/sri_lanka_phone_utils.dart';

/// Page to add a new student.
///
/// Firebase path: [schools] / [school_id] / [students] / [document_id]
/// Document ID = normalized parent mobile number (digits only). Login uses this for 1-read lookup.
/// Student document schema: student_id (= doc id), full_name, parent_phone, password, etc.
class AddStudentPage extends StatefulWidget {
  final String? schoolId;

  const AddStudentPage({super.key, this.schoolId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  static const double _maxContentWidth = 700;

  final _formKey = GlobalKey<FormState>();
  final _schoolIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _districtController = TextEditingController();
  final _emailController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _birthday;
  bool _isSaving = false;

  late final List<String> _gradeOptions = List.from(AppConstants.gradeOptions)
    ..removeWhere((g) => g == 'All');
  String? _selectedGrade;

  static const List<String> _genderOptions = ['Male', 'Female'];
  String? _selectedGender;

  static const List<String> _sriLankaDistricts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Monaragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya',
  ];
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _prefillSchoolIdIfLoggedIn();
  }

  Future<void> _prefillSchoolIdIfLoggedIn() async {
    final user = await UserSessionService.getCurrentUser();
    if (mounted && user?.teacherId != null && user!.teacherId!.isNotEmpty) {
      _schoolIdController.text = user.teacherId!;
    }
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _districtController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  /// School ID: form field when entered, else logged-in user / widget. Path: schools/{schoolId}/students.
  Future<String?> _getSchoolId() async {
    final fromForm = _schoolIdController.text.trim();
    if (fromForm.isNotEmpty) return fromForm;
    final user = await UserSessionService.getCurrentUser();
    return user?.teacherId ?? widget.schoolId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthday == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select birthday'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedGrade == null || _selectedGrade!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select grade'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select gender'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedDistrict == null || _selectedDistrict!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select district'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a password'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password and Confirm password do not match'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final schoolId = await _getSchoolId();
    final schoolIdFormatError = SchoolValidationService.validateSchoolIdFormat(schoolId);
    if (schoolIdFormatError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(schoolIdFormatError),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final schoolExists =
          await SchoolValidationService.schoolExists(schoolId!);
      if (!schoolExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'School ID / Teacher ID not found. Please check the ID and try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final now = FieldValue.serverTimestamp();
      final dateOfBirth =
          '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}';
      final gradeValue = 'Grade $_selectedGrade';
      final parentPhoneRaw = _phoneController.text.trim();
      final localMobile =
          SriLankaPhoneUtils.normalizeRegistrationMobile(parentPhoneRaw);
      if (localMobile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                SriLankaPhoneUtils.validateRegistrationMobileField(
                      parentPhoneRaw,
                    ) ??
                    'Please enter a valid Sri Lanka mobile number.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isSaving = false);
        }
        return;
      }
      final documentId = localMobile;

      final alreadyRegistered = await SchoolValidationService.studentExists(
        schoolId,
        localMobile,
      );
      if (alreadyRegistered) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'A student with mobile number $localMobile is already registered under this School ID.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final studentsRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students');

      final parentName = _parentNameController.text.trim();
      final parentEmail = _emailController.text.trim();

      await studentsRef.doc(documentId).set({
        'student_id': documentId,
        'full_name': _nameController.text.trim(),
        'gender': _selectedGender,
        'date_of_birth': dateOfBirth,
        'grade': gradeValue,
        'parent_name': parentName.isEmpty ? null : parentName,
        'parent_phone': localMobile,
        'parent_email': parentEmail.isEmpty ? null : parentEmail,
        'address': _districtController.text.trim(),
        'district': _selectedDistrict,
        'status': 'active',
        'password': password,
        'joined_date': now,
        'created_at': now,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student added. Login with mobile number: $localMobile',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Add Student'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildField(
                  controller: _schoolIdController,
                  label: 'School ID / Teacher ID',
                  hint: 'Enter 6-digit school or teacher ID',
                  icon: Icons.school,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (v) =>
                      SchoolValidationService.validateSchoolIdFormat(v),
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _nameController,
                  label: 'Student Name',
                  hint: 'e.g. Saman Perera',
                  icon: Icons.person,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Full name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _phoneController,
                  label: 'Parent mobile (Sri Lanka)',
                  hint: 'e.g. 0771234567 (070–078)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [_RegistrationMobileInputFormatter()],
                  validator: (v) =>
                      SriLankaPhoneUtils.validateRegistrationMobileField(v),
                ),
                const SizedBox(height: 16),
                _buildGenderDropdown(),
                const SizedBox(height: 16),
                _buildBirthdayField(),
                const SizedBox(height: 16),
                _buildGradeDropdown(),
                const SizedBox(height: 16),
                _buildField(
                  controller: _parentNameController,
                  label: 'Parent Name',
                  hint: 'e.g. Nimal Perera',
                  icon: Icons.people,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _emailController,
                  label: 'Parent Email',
                  hint: 'e.g. parent@gmail.com',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _districtController,
                  label: 'Address',
                  hint: 'e.g. Street, city',
                  icon: Icons.location_on,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Address is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDistrictDropdown(),
                const SizedBox(height: 16),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Please confirm password';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enableInteractiveSelection = true,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enableInteractiveSelection: enableInteractiveSelection,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.wc, color: Color(0xFF667eea)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: const Text('Select gender'),
      items: _genderOptions
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (value) => setState(() => _selectedGender = value),
      validator: (v) => (_selectedGender == null || _selectedGender!.isEmpty)
          ? 'Gender is required'
          : null,
    );
  }

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGrade,
      decoration: InputDecoration(
        labelText: 'Grade',
        prefixIcon: const Icon(Icons.grade, color: Color(0xFF667eea)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: const Text('Select grade'),
      items: _gradeOptions
          .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g')))
          .toList(),
      onChanged: (value) => setState(() => _selectedGrade = value),
      validator: (v) => (_selectedGrade == null || _selectedGrade!.isEmpty)
          ? 'Grade is required'
          : null,
    );
  }

  Widget _buildDistrictDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDistrict,
      decoration: InputDecoration(
        labelText: 'Select District',
        prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF667eea)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: const Text('Select district'),
      items: _sriLankaDistricts
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (value) => setState(() => _selectedDistrict = value),
      validator: (v) =>
          (_selectedDistrict == null || _selectedDistrict!.isEmpty)
          ? 'District is required'
          : null,
    );
  }

  Widget _buildBirthdayField() {
    return InkWell(
      onTap: _isSaving ? null : _pickBirthday,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birthday',
          hintText: 'Select birthday',
          prefixIcon: const Icon(Icons.cake, color: Color(0xFF667eea)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          _birthday == null
              ? 'Select birthday'
              : '${_birthday!.day}/${_birthday!.month}/${_birthday!.year}',
          style: TextStyle(
            color: _birthday == null
                ? Colors.grey[600]
                : const Color(0xFF2D3436),
          ),
        ),
      ),
    );
  }
}

/// Blocks invalid country codes and operator prefixes on registration only.
class _RegistrationMobileInputFormatter extends TextInputFormatter {
  const _RegistrationMobileInputFormatter();

  static final RegExp _digitsOnly = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.contains('+')) return oldValue;
    final digits = text.replaceAll(_digitsOnly, '');
    if (digits.startsWith('94')) return oldValue;
    if (digits.isNotEmpty && digits[0] != '0') return oldValue;
    if (digits.length >= 2 && digits[1] != '7') return oldValue;
    if (digits.length >= 3) {
      final prefix = digits.substring(0, 3);
      if (!SriLankaPhoneUtils.registrationMobilePrefixes.contains(prefix)) {
        return oldValue;
      }
    }
    if (digits.length > 10) return oldValue;
    return newValue;
  }
}
