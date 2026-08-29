import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/app_config.dart';
import '../../core/enums/vendor_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../routes/app_routes.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToStatusChanges();
    });
  }

  void _listenToStatusChanges() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    if (authProvider.user != null) {
      // Listen for real-time status updates
      vendorProvider.listenToVendorStatus(authProvider.user!.uid);
    }
  }

  Future<void> _callAdmin() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: AppConfig.adminPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _whatsappAdmin() async {
    final phone = AppConfig.adminPhone.replaceAll('+', '');
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phone?text=Hi, I have registered on IronCreeze Partner app and waiting for approval.',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout', style: AppTextStyles.heading6),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                AppRoutes.navigateAndClearStack(context, AppRoutes.login);
              }
            },
            child: Text(
              'Logout',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<VendorProvider>(
          builder: (context, vendorProvider, child) {
            final status = vendorProvider.vendorStatus;

            // Navigate to home if approved
            if (status == VendorStatus.approved) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AppRoutes.navigateAndClearStack(
                  context,
                  AppRoutes.mainNavigation,
                );
              });
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Logout Button
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        onPressed: _handleLogout,
                        icon: const Icon(
                          Icons.logout,
                          size: 20,
                          color: AppColors.error,
                        ),
                        label: Text(
                          'Logout',
                          style: AppTextStyles.buttonMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status Icon with background
                    _buildStatusIcon(status),
                    const SizedBox(height: 32),

                    // Status Title
                    Text(
                      _getStatusTitle(status),
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Status Description
                    Text(
                      _getStatusDescription(status),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Progress Indicator (only for pending status)
                    if (status == VendorStatus.pending)
                      _buildProgressIndicator(),

                    if (status == VendorStatus.approved)
                      _buildApprovedProgressIndicator(),

                    const SizedBox(height: 48),

                    // What's Next Section
                    if (status == VendorStatus.pending)
                      _buildWhatsNextSection(),

                    if (status == VendorStatus.approved)
                      _buildApprovedSection(),

                    // Rejected Message
                    if (status == VendorStatus.rejected)
                      _buildRejectedSection(
                        vendorProvider.vendor?.rejectionReason,
                      ),

                    // Suspended Message
                    if (status == VendorStatus.suspended)
                      _buildSuspendedSection(),

                    const SizedBox(height: 32),

                    // Check Status / Go to Dashboard Button
                    if (status == VendorStatus.pending)
                      CustomButton(
                        text: 'Check Status',
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (authProvider.user != null) {
                            await vendorProvider.fetchVendor(
                              authProvider.user!.uid,
                            );
                          }
                        },
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                      ),

                    if (status == VendorStatus.approved)
                      CustomButton(
                        text: 'Go to Dashboard',
                        onPressed: () {
                          AppRoutes.navigateAndClearStack(
                            context,
                            AppRoutes.mainNavigation,
                          );
                        },
                        type: ButtonType.primary,
                        size: ButtonSize.large,
                      ),

                    const SizedBox(height: 24),

                    // Need Help Section
                    _buildNeedHelpSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIcon(VendorStatus status) {
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (status) {
      case VendorStatus.pending:
        icon = Icons.hourglass_top_rounded;
        iconColor = AppColors.warning;
        bgColor = const Color(0xFFFFF3E0); // Light orange
        break;
      case VendorStatus.rejected:
        icon = Icons.cancel_outlined;
        iconColor = AppColors.error;
        bgColor = AppColors.errorLight;
        break;
      case VendorStatus.approved:
        icon = Icons.check_circle_outline;
        iconColor = AppColors.success;
        bgColor = AppColors.successLight;
        break;
      case VendorStatus.suspended:
        icon = Icons.block;
        iconColor = AppColors.error;
        bgColor = AppColors.errorLight;
        break;
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, size: 70, color: iconColor),
    );
  }

  String _getStatusTitle(VendorStatus status) {
    switch (status) {
      case VendorStatus.pending:
        return 'Application Under Review';
      case VendorStatus.rejected:
        return 'Application Rejected';
      case VendorStatus.approved:
        return 'Application Approved!';
      case VendorStatus.suspended:
        return 'Account Suspended';
    }
  }

  String _getStatusDescription(VendorStatus status) {
    switch (status) {
      case VendorStatus.pending:
        return 'Your vendor application is currently being reviewed by our team. This process typically takes 24-48 hours.';
      case VendorStatus.rejected:
        return 'Unfortunately, your application has been rejected. Please contact our support team for more details.';
      case VendorStatus.approved:
        return 'Congratulations! Your account has been approved. You can now start using the dashboard.';
      case VendorStatus.suspended:
        return 'Your account has been suspended. Please contact our support team for more information.';
    }
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildProgressStep(
                icon: Icons.check_circle,
                label: 'Profile\nSubmitted',
                isCompleted: true,
                isActive: true,
              ),
            ),
            Expanded(
              child: _buildProgressStep(
                icon: Icons.hourglass_top_rounded,
                label: 'Under\nReview',
                isCompleted: false,
                isActive: true,
              ),
            ),
            Expanded(
              child: _buildProgressStep(
                icon: Icons.check_circle_outline,
                label: 'Approved',
                isCompleted: false,
                isActive: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildApprovedProgressIndicator() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildProgressStep(
                icon: Icons.check_circle,
                label: 'Profile\nSubmitted',
                isCompleted: true,
                isActive: true,
              ),
            ),
            Expanded(
              child: _buildProgressStep(
                icon: Icons.check_circle,
                label: 'Under\nReview',
                isCompleted: true,
                isActive: true,
              ),
            ),
            Expanded(
              child: _buildProgressStep(
                icon: Icons.check_circle,
                label: 'Approved',
                isCompleted: true,
                isActive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressStep({
    required IconData icon,
    required String label,
    required bool isCompleted,
    required bool isActive,
  }) {
    Color iconColor;
    Color bgColor;
    Color textColor;

    if (isCompleted) {
      iconColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.1);
      textColor = AppColors.textPrimary;
    } else if (isActive) {
      iconColor = AppColors.warning;
      bgColor = AppColors.warning.withOpacity(0.1);
      textColor = AppColors.textPrimary;
    } else {
      iconColor = AppColors.grey300;
      bgColor = AppColors.grey100;
      textColor = AppColors.textSecondary;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWhatsNextSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("What's Next?", style: AppTextStyles.heading6),
          const SizedBox(height: 20),
          _buildNextStep(
            icon: Icons.notifications_active,
            title:
                "You'll receive a notification once your application is approved",
          ),
          const SizedBox(height: 16),
          _buildNextStep(
            icon: Icons.mail_outline,
            title: "We'll also send you an email with further instructions",
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep({required IconData icon, required String title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.warning, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Account Activated',
                style: AppTextStyles.heading6.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your vendor account is now active and ready to use. You can access all features from the dashboard.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedSection(String? reason) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Text(
                'Rejection Reason',
                style: AppTextStyles.heading6.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reason ??
                'No specific reason provided. Please contact admin for details.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Contact Admin',
            onPressed: _whatsappAdmin,
            type: ButtonType.primary,
            backgroundColor: AppColors.error,
            prefixIcon: Icons.support_agent,
          ),
        ],
      ),
    );
  }

  Widget _buildSuspendedSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Text(
                'Account Suspended',
                style: AppTextStyles.heading6.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your account has been suspended. Please contact our support team for more information.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Contact Admin',
            onPressed: _whatsappAdmin,
            type: ButtonType.primary,
            backgroundColor: AppColors.error,
            prefixIcon: Icons.support_agent,
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Need Help?', style: AppTextStyles.heading6),
          const SizedBox(height: 8),
          Text(
            'Contact our support team for any queries',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppConfig.adminPhone,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: AppConfig.adminPhone),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.copy,
                    color: AppColors.grey500,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Call',
                  onPressed: _callAdmin,
                  type: ButtonType.outline,
                  size: ButtonSize.medium,
                  prefixIcon: Icons.call,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'WhatsApp',
                  onPressed: _whatsappAdmin,
                  type: ButtonType.primary,
                  size: ButtonSize.medium,
                  prefixIcon: Icons.message,
                  backgroundColor: const Color(0xFF25D366),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
