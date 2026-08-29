import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_app_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    Helpers.hideKeyboard(context);

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.resetPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _emailSent = true);
    } else {
      Helpers.showErrorToast(
        authProvider.error ?? 'Failed to send reset email',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: '', showBackButton: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 40),

          // Email Field
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'Enter your registered email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.validateEmail,
            onSubmitted: (_) => _handleResetPassword(),
          ),

          const SizedBox(height: 32),

          // Reset Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 24),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to Login',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 32,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        Text('Forgot Password?', style: AppTextStyles.heading3),

        const SizedBox(height: 8),

        Text(
          "Don't worry! Enter your registered email address and we'll send you a link to reset your password.",
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Success Icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            size: 50,
            color: AppColors.success,
          ),
        ),

        const SizedBox(height: 32),

        Text(
          'Email Sent!',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        Text(
          'We have sent a password reset link to:',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          _emailController.text.trim(),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Please check your spam folder if you don\'t see the email in your inbox.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Back to Login Button
        CustomButton(
          text: 'Back to Login',
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),

        const SizedBox(height: 16),

        // Resend Email
        TextButton(
          onPressed: () {
            setState(() => _emailSent = false);
          },
          child: Text(
            'Didn\'t receive email? Try again',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
