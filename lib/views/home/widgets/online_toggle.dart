import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';

class OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final bool isLoading;
  final ValueChanged<bool>? onChanged;

  const OnlineToggle({
    super.key,
    required this.isOnline,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged?.call(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isOnline ? AppColors.success : AppColors.grey200,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isOnline
              ? [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOnline ? AppColors.white : AppColors.grey600,
                  ),
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.white : AppColors.grey500,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              isOnline ? 'Online' : 'Offline',
              style: AppTextStyles.labelMedium.copyWith(
                color: isOnline ? AppColors.white : AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
