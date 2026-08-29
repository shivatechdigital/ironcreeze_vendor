import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import 'custom_button.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (confirmColor ?? AppColors.primary).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: confirmColor ?? AppColors.primary,
                  size: 32,
                ),
              ),
            if (icon != null) const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: cancelText,
                    onPressed: () => Navigator.pop(
                      context,
                      false,
                    ), // ✅ Direct pop with value
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: confirmText,
                    onPressed: () =>
                        Navigator.pop(context, true), // ✅ Direct pop with value
                    type: ButtonType.primary,
                    size: ButtonSize.medium,
                    backgroundColor: confirmColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Clean static method
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }
}
