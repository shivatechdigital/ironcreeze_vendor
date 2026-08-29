import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_config.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import '../../core/enums/vendor_status.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpVerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendTimer = AppConfig.otpResendTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // Auto focus on OTP field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer = AppConfig.otpResendTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      Helpers.showErrorToast('Please enter 6-digit OTP');
      return;
    }

    Helpers.hideKeyboard(context);

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.verifyOTP(otp: otp);

    setState(() => _isLoading = false);

    if (success) {
      _navigateAfterAuth();
    } else {
      Helpers.showErrorToast(authProvider.error ?? 'Invalid OTP');
      _otpController.clear();
    }
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.sendOTP(phoneNumber: widget.phoneNumber);

    setState(() => _isResending = false);

    if (authProvider.verificationId != null) {
      Helpers.showSuccessToast('OTP sent successfully');
      _startResendTimer();
      _otpController.clear();
    } else if (authProvider.error != null) {
      Helpers.showErrorToast(authProvider.error!);
    }
  }

  Future<void> _navigateAfterAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    if (authProvider.user == null) return;

    // Check if vendor profile exists
    final vendorExists = await vendorProvider.checkVendorExists(
      authProvider.user!.uid,
    );

    if (!mounted) return;

    if (vendorExists) {
      await vendorProvider.fetchVendor(authProvider.user!.uid);

      if (!mounted) return;

      if (vendorProvider.vendorStatus == VendorStatus.approved) {
        AppRoutes.navigateAndClearStack(context, AppRoutes.mainNavigation);
      } else {
        AppRoutes.navigateAndClearStack(context, AppRoutes.pendingApproval);
      }
    } else {
      // New user - needs to complete registration
      AppRoutes.navigateAndClearStack(
        context,
        AppRoutes.vendorDetails,
        arguments: {
          'email': null,
          'phone': widget.phoneNumber,
          'authType': 'phone',
        },
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 40),

              // OTP Input
              _buildOtpInput(),

              const SizedBox(height: 32),

              // Verify Button
              CustomButton(
                text: 'Verify OTP',
                onPressed: _verifyOTP,
                isLoading: _isLoading,
              ),

              const SizedBox(height: 24),

              // Resend OTP
              _buildResendSection(),

              const Spacer(),

              // Help Text
              // _buildHelpText(),
            ],
          ),
        ),
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
            Icons.phone_android,
            size: 32,
            color: AppColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        Text('Verify Phone Number', style: AppTextStyles.heading3),

        const SizedBox(height: 8),

        RichText(
          text: TextSpan(
            text: 'We have sent a 6-digit OTP to ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: '+91 ${widget.phoneNumber}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: AppTextStyles.heading4.copyWith(color: AppColors.textPrimary),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
    );

    return Center(
      child: Pinput(
        controller: _otpController,
        focusNode: _focusNode,
        length: 6,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.primary, width: 2),
          ),
        ),
        errorPinTheme: defaultPinTheme.copyWith(
          decoration: defaultPinTheme.decoration!.copyWith(
            border: Border.all(color: AppColors.error),
          ),
        ),
        onCompleted: (pin) {
          _verifyOTP();
        },
        keyboardType: TextInputType.number,
        showCursor: true,
        cursor: Container(
          width: 2,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: _resendTimer > 0
          ? RichText(
              text: TextSpan(
                text: 'Resend OTP in ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '${_resendTimer}s',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : _isResending
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : TextButton(
              onPressed: _resendOTP,
              child: Text(
                'Resend OTP',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildHelpText() {
    return Container(
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
              'Make sure you have network connectivity to receive OTP via SMS.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}
