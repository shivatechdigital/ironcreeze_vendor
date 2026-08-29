import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../routes/app_routes.dart';
import '../../core/enums/vendor_status.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPhoneLogin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;

  bool get _showGoogleSignIn =>
      kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Phone Login — OTP bhejo
  // ✅ FIX: Pehle OTP screen open karo, phir background mein OTP bhejo
  // ─────────────────────────────────────────────
  Future<void> _handlePhoneLogin() async {
    debugPrint('🔴 Send OTP button pressed');

    final phone = _phoneController.text.trim();
    debugPrint('📱 Phone entered: "$phone"');

    // ✅ Inline validation — Validators pe depend mat karo
    if (phone.isEmpty) {
      Helpers.showErrorToast('Please enter your mobile number');
      return;
    }
    if (phone.length != 10) {
      Helpers.showErrorToast('Enter valid 10-digit mobile number');
      return;
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      Helpers.showErrorToast('Enter valid Indian mobile number');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isPhoneLoading = true);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    // ✅ Step 1: Turant OTP screen open karo
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      AppRoutes.otpVerification,
      arguments: {
        'verificationId':
            'pending', // placeholder — baad mein AuthProvider se milega
        'phoneNumber': phone,
      },
    );

    setState(() => _isPhoneLoading = false);

    // ✅ Step 2: Background mein OTP bhejo
    debugPrint('📞 Sending OTP in background for: +91$phone');
    final success = await authProvider.sendOTP(phoneNumber: phone);

    debugPrint('📱 sendOTP result: $success | status: ${authProvider.status}');

    // ✅ Agar OTP send fail hua to error dikhao
    if (!success && mounted) {
      Helpers.showErrorToast(
        authProvider.error ?? 'Failed to send OTP. Please try again.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // Email Login
  // ─────────────────────────────────────────────
  Future<void> _handleEmailLogin() async {
    debugPrint('🔴 Email login button pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    debugPrint('📧 signInWithEmail result: $success');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _navigateAfterAuth();
    } else {
      Helpers.showErrorToast(authProvider.error ?? 'Login failed');
    }
  }

  // ─────────────────────────────────────────────
  // Google Login
  // ─────────────────────────────────────────────
  Future<void> _handleGoogleLogin() async {
    debugPrint('🔴 Google login button pressed');
    setState(() => _isGoogleLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();

    debugPrint('🟢 signInWithGoogle result: $success');

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (success) {
      _navigateAfterAuth();
    } else if (authProvider.error != null) {
      Helpers.showErrorToast(authProvider.error!);
    }
  }

  // ─────────────────────────────────────────────
  // Navigate After Auth
  // ─────────────────────────────────────────────
  Future<void> _navigateAfterAuth() async {
    debugPrint('🧭 _navigateAfterAuth called');

    final authProvider = context.read<AuthProvider>();
    final vendorProvider = context.read<VendorProvider>();

    if (authProvider.user == null) return;

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final vendorExists = await vendorProvider.checkVendorExists(
      authProvider.user!.uid,
    );

    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (vendorExists) {
      await vendorProvider.fetchVendor(authProvider.user!.uid);
      if (!mounted) return;

      if (vendorProvider.vendorStatus == VendorStatus.approved) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.mainNavigation);
      } else {
        AppRoutes.navigateAndClearStack(context, AppRoutes.pendingApproval);
      }
    } else {
      AppRoutes.navigateAndClearStack(
        context,
        AppRoutes.vendorDetails,
        arguments: {
          'email': authProvider.user!.email,
          'phone': authProvider.user!.phoneNumber?.replaceAll('+91', ''),
          'authType': authProvider.authType?.value,
        },
      );
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Top Image (70%) ──
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/iron.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: Image.asset('assets/logo.png', width: 65, height: 65),
                ),
              ],
            ),
          ),

          // ── Bottom White Box (30%) ──
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isPhoneLogin
                              ? "You're Almost There"
                              : "Welcome Back! 👋",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        if (_isPhoneLogin)
                          _buildPhoneLoginForm()
                        else
                          _buildEmailLoginForm(),

                        const SizedBox(height: 16),

                        _buildDivider(),

                        const SizedBox(height: 16),

                        _buildSocialLogins(),

                        const SizedBox(height: 16),

                        _buildSignUpLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Phone Form
  // ─────────────────────────────────────────────
  Widget _buildPhoneLoginForm() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8E8E8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Text(
                  '+91',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Container(height: 20, width: 0.8, color: const Color(0xFFD0D0D0)),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    hintText: 'Enter Mobile Number',
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onFieldSubmitted: (_) => _handlePhoneLogin(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: _isPhoneLoading ? null : _handlePhoneLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8730F),
              disabledBackgroundColor: const Color(0xFFCCC8C0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isPhoneLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Email Form
  // ─────────────────────────────────────────────
  Widget _buildEmailLoginForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.done,
          validator: Validators.validatePassword,
          onSubmitted: (_) => _handleEmailLogin(),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.forgotPassword),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: CustomButton(
            text: 'Sign In',
            onPressed: _handleEmailLogin,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // OR Divider
  // ─────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFE8E8E8)],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8E8E8), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Social Buttons
  // ─────────────────────────────────────────────
  Widget _buildSocialLogins() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_showGoogleSignIn) ...[
          GestureDetector(
            onTap: _isGoogleLoading ? null : _handleGoogleLogin,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: _isGoogleLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF4285F4),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.g_translate,
                      color: Color(0xFF4285F4),
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Toggle Phone / Email
        GestureDetector(
          onTap: () {
            setState(() {
              _isPhoneLogin = !_isPhoneLogin;
              _emailController.clear();
              _passwordController.clear();
              _phoneController.clear();
            });
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Icon(
              _isPhoneLogin ? Icons.email_outlined : Icons.phone_outlined,
              color: const Color(0xFFE8730F),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Sign Up Link
  // ─────────────────────────────────────────────
  Widget _buildSignUpLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: "Don't have an account? ",
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          children: [
            TextSpan(
              text: 'Sign Up',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE8730F),
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  debugPrint('🔴 Sign Up tapped');
                  Navigator.pushNamed(context, AppRoutes.signup);
                },
            ),
          ],
        ),
      ),
    );
  }
}
