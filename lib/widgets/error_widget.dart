import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import 'custom_button.dart';

class CustomErrorWidget extends StatelessWidget {
  final String? title;
  final String message;
  final String? buttonText;
  final VoidCallback? onRetry;
  final IconData? icon;

  const CustomErrorWidget({
    super.key,
    this.title,
    required this.message,
    this.buttonText,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            if (title != null)
              Text(
                title!,
                style: AppTextStyles.heading5,
                textAlign: TextAlign.center,
              ),
            if (title != null) const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: buttonText ?? 'Try Again',
                onPressed: onRetry,
                type: ButtonType.primary,
                size: ButtonSize.medium,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// No Internet Widget
class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      icon: Icons.wifi_off_rounded,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      buttonText: 'Retry',
      onRetry: onRetry,
    );
  }
}
