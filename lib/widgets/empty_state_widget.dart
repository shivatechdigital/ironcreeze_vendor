import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import 'custom_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.grey400, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.heading5,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              CustomButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                type: ButtonType.primary,
                size: ButtonSize.medium,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
