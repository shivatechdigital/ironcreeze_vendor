import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../core/constants/app_constants.dart';

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double? width;
  final Color? backgroundColor;
  final Color? textColor;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.large,
    this.isLoading = false,
    this.isDisabled = false,
    this.prefixIcon,
    this.suffixIcon,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: _getHeight(),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    final isEnabled = !isDisabled && !isLoading && onPressed != null;

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: textColor ?? AppColors.white,
            disabledBackgroundColor: AppColors.grey300,
            disabledForegroundColor: AppColors.grey500,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radiusM,
              ),
            ),
          ),
          child: _buildChild(textColor ?? AppColors.white),
        );

      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primaryBackground,
            foregroundColor: textColor ?? AppColors.primary,
            disabledBackgroundColor: AppColors.grey100,
            disabledForegroundColor: AppColors.grey400,
            padding: _getPadding(),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radiusM,
              ),
            ),
          ),
          child: _buildChild(textColor ?? AppColors.primary),
        );

      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.grey400,
            padding: _getPadding(),
            side: BorderSide(
              color: isEnabled
                  ? (backgroundColor ?? AppColors.primary)
                  : AppColors.grey300,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppConstants.radiusM,
              ),
            ),
          ),
          child: _buildChild(textColor ?? AppColors.primary),
        );

      case ButtonType.text:
        return TextButton(
          onPressed: isEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? AppColors.primary,
            disabledForegroundColor: AppColors.grey400,
            padding: _getPadding(),
          ),
          child: _buildChild(textColor ?? AppColors.primary),
        );
    }
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            type == ButtonType.primary ? AppColors.white : AppColors.primary,
          ),
        ),
      );
    }

    final textStyle = _getTextStyle().copyWith(color: color);

    if (prefixIcon != null || suffixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (prefixIcon != null) ...[
            Icon(prefixIcon, size: _getIconSize(), color: color),
            const SizedBox(width: 8),
          ],
          Text(text, style: textStyle),
          if (suffixIcon != null) ...[
            const SizedBox(width: 8),
            Icon(suffixIcon, size: _getIconSize(), color: color),
          ],
        ],
      );
    }

    return Text(text, style: textStyle);
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return AppTextStyles.buttonSmall;
      case ButtonSize.medium:
        return AppTextStyles.buttonMedium;
      case ButtonSize.large:
        return AppTextStyles.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 18;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 22;
    }
  }
}
