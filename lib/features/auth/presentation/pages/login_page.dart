import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../../../../core/utils/sri_lanka_phone_utils.dart';
import '../constants/strings.dart';
import '../bloc/auth_bloc.dart';
import 'signup_page.dart';
import 'reset_password_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController _schoolIdController;
  late TextEditingController _passwordController;
  late TextEditingController _studentUsernameController;
  String? _lastErrorMessage;
  bool _hasShownError = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _lightBlueBg = Color(0xFFE3F2FD);
  static const Color _labelGrey = Color(0xFF424242);
  static const Color _hintGrey = Color(0xFF9E9E9E);
  static const Color _borderGrey = Color(0xFFE0E0E0);
  static const Color _pageBg = Color(0xFFEFF3FF);

  @override
  void initState() {
    super.initState();
    _schoolIdController = TextEditingController();
    _passwordController = TextEditingController();
    _studentUsernameController = TextEditingController();
  }

  @override
  void dispose() {
    _schoolIdController.dispose();
    _passwordController.dispose();
    _studentUsernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
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
              Future.delayed(const Duration(seconds: 5), () {
                if (mounted) _hasShownError = false;
              });
            }
            if (state.errorMessage != _lastErrorMessage) {
              _lastErrorMessage = state.errorMessage;
              _hasShownError = false;
            }
          },
          builder: (context, state) {
            final size = MediaQuery.of(context).size;
            final isDesktop = size.width >= 1000;
            final cardHeight = (size.height - 180).clamp(500.0, 620.0).toDouble();

            return Column(
              children: [
                _buildTopBrand(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 900 : 600,
                        ),
                        child: _buildLoginCard(state, isDesktop, cardHeight),
                      ),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
         
        ],
      ),
    );
  }

  Widget _buildLoginCard(AuthState state, bool isDesktop, double cardHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: isDesktop
          ? SizedBox(
              height: cardHeight,
              child: Row(
                children: [
                  Expanded(flex: 50, child: _buildLeftArtworkPanel()),
                  Expanded(flex: 50, child: _buildLoginFormPanel(state, dense: true)),
                ],
              ),
            )
          : _buildLoginFormPanel(state, compact: true),
    );
  }

  Widget _buildLeftArtworkPanel() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(30),
        bottomLeft: Radius.circular(30),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A73E8), Color(0xFF2E78E3)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Class Teacher',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
           
          
            const SizedBox(height: 28),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/login_left_design_items.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildLoginFormPanel(
    AuthState state, {
    bool compact = false,
    bool dense = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraDense = dense && constraints.maxHeight < 510;
        final showBottomStrip = !dense || constraints.maxHeight >= 500;
        final horizontalPadding = compact ? 20.0 : (dense ? (ultraDense ? 22.0 : 30.0) : 48.0);
        final verticalPadding = compact ? 20.0 : (dense ? (ultraDense ? 8.0 : 12.0) : 44.0);
        final titleSize = ultraDense ? 20.0 : 22.0;
        final subtitleSize = ultraDense ? 13.0 : 14.0;
        final labelGap = ultraDense ? 2.0 : 4.0;
        final sectionGap = ultraDense ? 6.0 : 8.0;
        final introGap = ultraDense ? 8.0 : 12.0;
        final buttonHeight = ultraDense ? 42.0 : 46.0;
        final buttonTextSize = ultraDense ? 14.0 : 15.0;
        final actionTextSize = ultraDense ? 13.0 : 14.0;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: dense ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Text(
                'Student Login',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: ultraDense ? 4 : 8),
              if (!ultraDense)
                Text(
                  'Please enter your details to access your classroom.',
                  style: TextStyle(fontSize: subtitleSize, color: const Color(0xFF6B7280)),
                ),
              SizedBox(height: introGap),
              _buildLabel('Teacher ID / Institute ID'),
              SizedBox(height: labelGap),
              _buildTextField(
                controller: _schoolIdController,
                hintText: 'e.g. INS-12345',
                icon: Icons.badge_outlined,
              ),
              SizedBox(height: sectionGap),
              _buildLabel('Phone number'),
              SizedBox(height: labelGap),
              TextField(
                controller: _studentUsernameController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(
                  hintText: '7x xxx xxxx',
                  icon: Icons.phone_android_rounded,
                ),
              ),
              SizedBox(height: sectionGap),
              _buildLabel('Password'),
              SizedBox(height: labelGap),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  hintText: 'Password',
                  icon: Icons.lock_outline_rounded,
                  errorText: state.hasSubmitted ? state.passwordError : null,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _hintGrey,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                onChanged: (v) => context.read<AuthBloc>().add(PasswordChanged(v)),
              ),
              SizedBox(height: ultraDense ? 4 : 6),
              Row(
                children: [
                  SizedBox(
                    height: 22,
                    width: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                      activeColor: _primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Remember me',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ResetPasswordDialog(
                          initialSchoolId: _schoolIdController.text.trim().isEmpty
                              ? null
                              : _schoolIdController.text.trim(),
                          initialPhone: SriLankaPhoneUtils.normalizeToLocalTenDigits(
                            _studentUsernameController.text.trim(),
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontSize: 13,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ultraDense ? 6 : 10),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: state.status == FormzStatus.submissionInProgress
                      ? null
                      : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0x331976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: state.status == FormzStatus.submissionInProgress
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.login,
                              style: TextStyle(
                                fontSize: buttonTextSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 22),
                          ],
                        ),
                ),
              ),
              SizedBox(height: ultraDense ? 2 : 6),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AddStudentPage()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: actionTextSize, color: const Color(0xFF6B7280)),
                      children: [
                        const TextSpan(text: "Don’t have an account? "),
                        const TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (showBottomStrip) ...[
                SizedBox(height: ultraDense ? 4 : 8),
                const Divider(thickness: 1, color: Color(0xFFE5E7EB)),
                SizedBox(height: ultraDense ? 4 : 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BottomFeatureIcon(
                      icon: Icons.menu_book_rounded,
                      label: 'LESSONS',
                      bgColor: Color(0xFFFFE8CC),
                    ),
                    _BottomFeatureIcon(
                      icon: Icons.workspace_premium_rounded,
                      label: 'REWARDS',
                      bgColor: Color(0xFFEDE3FF),
                    ),
                    _BottomFeatureIcon(
                      icon: Icons.groups_2_rounded,
                      label: 'COMMUNITY',
                      bgColor: Color(0xFFDDEBFF),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: const [
          Text(
            '© 2024 My Class Teacher. Built for curious minds.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          Spacer(),
          Text(
            'Privacy Policy    Terms of Service    Contact Support',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _labelGrey,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    String? errorText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _hintGrey),
      prefixIcon: Icon(icon, size: 19, color: _hintGrey),
      filled: true,
      fillColor: const Color(0xFFF2F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      errorText: errorText,
      errorMaxLines: 2,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hintText: hintText, icon: icon),
    );
  }

  void _onLoginPressed() {
    // Teacher ID / Institute ID = school document ID (schools/{schoolId}/students)
    final schoolId = _schoolIdController.text.trim();
    final phoneInput = _studentUsernameController.text.trim();
    final username =
        SriLankaPhoneUtils.normalizeToLocalTenDigits(phoneInput) ?? '';
    final password = _passwordController.text;
    if (schoolId.isEmpty || phoneInput.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter Teacher ID / Institute ID, Parent's mobile number and Password",
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final phoneErr = SriLankaPhoneUtils.validateMobileField(phoneInput);
    if (phoneErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneErr), backgroundColor: Colors.orange),
      );
      return;
    }
    context.read<AuthBloc>().add(
      SignInStudentSubmitted(
        schoolId: schoolId,
        username: username,
        password: password,
        rememberMe: _rememberMe,
      ),
    );
  }
}

class _BottomFeatureIcon extends StatelessWidget {
  const _BottomFeatureIcon({
    required this.icon,
    required this.label,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
