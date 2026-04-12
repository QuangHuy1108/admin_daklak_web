import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth; 
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/auth_service.dart';
import '../utils/email_validator.dart';
import '../utils/firebase_exception_mapper.dart';
import '../presentation/widgets/auth_text_field.dart';
import '../presentation/widgets/auth_button.dart';
import '../presentation/widgets/auth_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_admin_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _rememberMe = true;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng nhập đầy đủ email và mật khẩu.');
      return;
    }

    if (!EmailValidator.isValid(email)) {
      _showError('Định dạng email không hợp lệ.');
      return;
    }

    // TODO: Analytics.track('login_attempt', {'email': email});

    String? error = await AuthService().loginAdmin(
      email: email,
      password: password,
    );

    if (error == null) {
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_admin_email', email);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_admin_email');
      }

      // TODO: Analytics.track('login_success');
      if (mounted) context.go('/dashboard');
    } else {
      // Map potential standard error keys out of the auth service response wrapper
      if (error.contains('[')) {
        final match = RegExp(r'\[([^\]]+)\]').firstMatch(error);
        final code = match != null ? match.group(1)!.split('/').last : error;
        final friendlyErr = FirebaseExceptionMapper.getFriendlyMessage(
          firebase_auth.FirebaseAuthException(code: code, message: error)
        );
        _showError(friendlyErr);
      } else {
        _showError(error);
      }
      // TODO: Analytics.track('login_failure', {'reason': error});
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    
    // We only open dialog if there's no email, or just open it anyway to confirm.
    final resetEmailController = TextEditingController(text: email);

    await AuthDialog.show(
      context: context,
      title: 'Quên Mật Khẩu?',
      description: 'Nhập email quản trị của bạn. Chúng tôi sẽ gửi một liên kết để thiết lập lại mật khẩu.',
      content: StatefulBuilder(
        builder: (context, setState) {
          return TextFormField(
            controller: resetEmailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      ),
      primaryButtonText: 'GỬI LIÊN KẾT',
      onPrimaryAction: () async {
        final targetEmail = resetEmailController.text.trim();
        if (!EmailValidator.isValid(targetEmail)) {
          _showError('Email không hợp lệ.');
          throw Exception('invalid email'); // throw just to prevent dialog close
        }

        try {
          await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: targetEmail);
          _showSuccess('Email khôi phục đã được gửi. Vui lòng kiểm tra hộp thư.');
          // TODO: Analytics.track('reset_password_sent');
        } on firebase_auth.FirebaseAuthException catch (e) {
          _showError(FirebaseExceptionMapper.getFriendlyMessage(e));
          rethrow; // prevent dialog close
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. App Background (Asset + Fallback Gradient)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A), // Fallback
              child: Image.network(
                'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=2940&auto=format&fit=crop',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.55),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) => const SizedBox(), 
              ),
            ),
          ),
          
          // Header Gradient Frame
          Positioned(
            top: 0, left: 0, right: 0, height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          // Footer Gradient Frame
          Positioned(
            bottom: 0, left: 0, right: 0, height: 260,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  const Icon(Icons.eco, color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Editorial Agronomy',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Coming Soon: Localization',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.language, color: Colors.white),
                        onPressed: null, 
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Tooltip(
                    message: 'Coming Soon: Theme Toggle',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.dark_mode, color: Colors.white),
                        onPressed: null, 
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Center Content (Login Form)
          Align(
            alignment: const Alignment(0, -0.15), // Offset slightly up from vertical center
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Icon & Title
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF156b2e),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF156b2e).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Smart Farming',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hệ thống quản lý admin_daklakweb',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Login Card
                  Container(
                    width: 380,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ĐĂNG NHẬP HỆ THỐNG',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF156b2e),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        AuthTextField(
                          label: 'Email Quản Trị',
                          hintText: 'admin@daklakweb.vn',
                          prefixIcon: Icons.alternate_email,
                          controller: _emailController,
                          focusNode: _emailFocus,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AuthTextField(
                          label: 'Mật Khẩu',
                          hintText: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Actions Row (Remember & Forgot PW)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => setState(() => _rememberMe = !_rememberMe),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.xs),
                                child: Row(
                                  children: [
                                    Icon(
                                      _rememberMe ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: _rememberMe ? AppColors.primary : AppColors.textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Ghi nhớ',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textHeading,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF156b2e),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              ),
                              child: Text(
                                'Quên mật khẩu?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        AuthButton(
                          label: 'Đăng Nhập Ngay',
                          suffixIcon: Icons.arrow_forward_rounded,
                          onPressed: _handleLogin, // Passed directly, concurrency natively managed
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.primary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'v2.4.0 Editorial Agronomy © 2024',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Footer Links
                  _buildFooterLink('PRIVACY POLICY'),
                  const SizedBox(width: AppSpacing.lg),
                  _buildFooterLink('TERMS OF SERVICE'),
                  const SizedBox(width: AppSpacing.lg),
                  _buildFooterLink('SUPPORT'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String title) {
    return InkWell(
      onTap: () {}, // Future routing
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}