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

class NewLoginPage extends StatefulWidget {
  const NewLoginPage({super.key});

  @override
  State<NewLoginPage> createState() => _NewLoginPageState();
}

class _NewLoginPageState extends State<NewLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isPhoneLogin = false;
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

  // Email Login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    Helpers.hideKeyboard(context);

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      _navigateAfterAuth();
    } else {
      Helpers.showErrorToast(authProvider.error ?? 'Login failed');
    }
  }

  // Google Login
  Future<void> _handleGoogleLogin() async {
    setState(() => _isGoogleLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (success) {
      _navigateAfterAuth();
    } else if (authProvider.error != null) {
      Helpers.showErrorToast(authProvider.error!);
    }
  }

  // Phone Login - Send OTP
  Future<void> _handlePhoneLogin() async {
    final phone = _phoneController.text.trim();

    debugPrint('📱 ========== PHONE LOGIN STARTED ==========');
    debugPrint('📱 Phone number: $phone');

    // Validate
    final validationError = Validators.validatePhone(phone);
    if (validationError != null) {
      Helpers.showErrorToast(validationError);
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isPhoneLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.clearError();

    // Send OTP and wait for result
    final success = await authProvider.sendOTP(phoneNumber: phone);

    setState(() => _isPhoneLoading = false);

    debugPrint('📱 sendOTP returned: $success');
    debugPrint('📱 Status: ${authProvider.status}');
    debugPrint('📱 Verification ID: ${authProvider.verificationId}');
    debugPrint('📱 Error: ${authProvider.error}');

    if (!mounted) return;

    // Check status
    if (authProvider.status == AuthStatus.authenticated) {
      // Auto-verified
      debugPrint('✅ Auto-verified! Navigating...');
      _navigateAfterAuth();
    } else if (authProvider.status == AuthStatus.codeSent &&
        authProvider.verificationId != null &&
        authProvider.verificationId!.isNotEmpty) {
      // OTP Sent - Navigate to OTP screen
      debugPrint('✅ OTP Sent! Navigating to OTP screen...');
      Navigator.pushNamed(
        context,
        AppRoutes.otpVerification,
        arguments: {
          'verificationId': authProvider.verificationId,
          'phoneNumber': phone,
        },
      );
    } else if (authProvider.error != null) {
      debugPrint('❌ Error: ${authProvider.error}');
      Helpers.showErrorToast(authProvider.error!);
    } else {
      debugPrint('⚠️ Unknown state');
      Helpers.showErrorToast('Something went wrong. Please try again.');
    }

    debugPrint('📱 ========== PHONE LOGIN ENDED ==========');
  }

  // Navigate After Auth
  Future<void> _navigateAfterAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    if (authProvider.user == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    // Check if vendor profile exists
    final vendorExists = await vendorProvider.checkVendorExists(
      authProvider.user!.uid,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (vendorExists) {
      // Fetch vendor data
      await vendorProvider.fetchVendor(authProvider.user!.uid);

      if (!mounted) return;

      // Check vendor status
      if (vendorProvider.vendorStatus == VendorStatus.approved) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.mainNavigation);
      } else {
        // Pending or Rejected
        AppRoutes.navigateAndClearStack(context, AppRoutes.pendingApproval);
      }
    } else {
      // New user - needs to complete registration
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// ========= 70% IMAGE =========
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

                /// Logo
                Positioned(
                  top: 50,
                  left: 20,
                  child: Image.asset('assets/logo.png', width: 65, height: 65),
                ),
              ],
            ),
          ),

          /// ========= 30% WHITE BOX =========
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
                        if (_isPhoneLogin)
                          const Text(
                            "You're Almost There",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          const Text(
                            "Welcome Back! 👋",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                        const SizedBox(height: 16),

                        if (_isPhoneLogin) ...[
                          _buildPhoneLoginForm(),
                        ] else ...[
                          _buildEmailLoginForm(),
                        ],

                        const SizedBox(height: 16),

                        /// Divider with OR text
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFE8E8E8),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
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
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFE8E8E8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /// Social Icons (Email & Google)
                        _buildSocialLogins(),

                        const SizedBox(height: 16),

                        /// Sign Up Link
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
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
            },
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
          height: 48,
          child: CustomButton(
            text: 'Sign In',
            onPressed: _handleEmailLogin,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLoginForm() {
    return Column(
      children: [
        /// Phone Input Field
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
                  "+91",
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
                  validator: Validators.validatePhone,
                  decoration: const InputDecoration(
                    hintText: "Enter Mobile Number",
                    border: InputBorder.none,
                    counterText: "",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        /// Send OTP Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isPhoneLoading ? null : _handlePhoneLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8730F),
              disabledBackgroundColor: const Color(0xFFCCC8C0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isPhoneLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Send OTP",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 12),

        /// Switch to Email Login
        TextButton.icon(
          onPressed: () {
            setState(() {
              _isPhoneLogin = false;
              _phoneController.clear();
            });
          },
          icon: const Icon(Icons.email_outlined, size: 18),
          label: Text(
            'Sign in with Email instead',
            style: TextStyle(
              color: const Color(0xFFE8730F),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

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
                  ? const SizedBox(
                      height: 20,
                      width: 20,
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

        /// Phone Icon (to toggle phone login)
        GestureDetector(
          onTap: () {
            setState(() {
              _isPhoneLogin = true;
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
            child: const Icon(
              Icons.phone_outlined,
              color: Color(0xFFE8730F),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

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
                  Navigator.pushNamed(context, AppRoutes.signup);
                },
            ),
          ],
        ),
      ),
    );
  }
}
