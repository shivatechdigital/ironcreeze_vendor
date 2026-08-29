import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../routes/app_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      Helpers.showErrorToast('Please accept Terms & Conditions');
      return;
    }

    Helpers.hideKeyboard(context);
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      AppRoutes.navigateAndClearStack(
        context,
        AppRoutes.vendorDetails,
        arguments: {
          'email': _emailController.text.trim(),
          'phone': null,
          'authType': 'email',
        },
      );
    } else if (authProvider.error != null) {
      Helpers.showErrorToast(authProvider.error!);
    }
  }

  Future<void> _handleGoogleSignup() async {
    if (!_acceptedTerms) {
      Helpers.showErrorToast('Please accept Terms & Conditions');
      return;
    }

    setState(() => _isGoogleLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();

    setState(() => _isGoogleLoading = false);

    if (success && mounted) {
      AppRoutes.navigateAndClearStack(
        context,
        AppRoutes.vendorDetails,
        arguments: {
          'email': authProvider.user?.email,
          'phone': null,
          'authType': 'google',
        },
      );
    } else if (authProvider.error != null) {
      Helpers.showErrorToast(authProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────
                Text('Create Account 🚀', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(
                  'Sign up to become an IronCreeze partner and start receiving orders.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email Field ───────────────────────────────────────
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // ── Password Field ────────────────────────────────────
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Create a strong password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // ── Confirm Password Field ────────────────────────────
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onSubmitted: (_) => _handleSignup(),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),

                // ── Terms & Conditions ────────────────────────────────
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => setState(
                                () => _acceptedTerms = !_acceptedTerms,
                              ),
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'I accept the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Open Terms of Service
                                  },
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Open Privacy Policy
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Signup Button ─────────────────────────────────────
                CustomButton(
                  text: 'Create Account',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                // ── OR Divider ────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Google Signup Button ──────────────────────────────
                _SocialButton(
                  text: 'Continue with Google',
                  icon: Icons.g_mobiledata_rounded,
                  backgroundColor: Colors.white,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.border,
                  onPressed: _handleGoogleSignup,
                  isLoading: _isGoogleLoading,
                ),
                const SizedBox(height: 32),

                // ── Login Link ────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign In',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SocialButton — replaces the old GoogleSignInButton widget
// Same style as customer app's SocialLoginButton
// ─────────────────────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
