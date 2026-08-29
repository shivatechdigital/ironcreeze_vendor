import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../core/constants/app_constants.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final String iconPath;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  const SocialButton({
    super.key,
    required this.text,
    required this.iconPath,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.white,
          foregroundColor: textColor ?? AppColors.textPrimary,
          side: BorderSide(color: borderColor ?? AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? AppColors.textPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return _getIconWidget();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: textColor ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _getIconWidget() {
    // Fallback icons if image not found
    if (iconPath.contains('google')) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'G',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    } else if (iconPath.contains('phone')) {
      return const Icon(
        Icons.phone_android,
        size: 24,
        color: AppColors.primary,
      );
    }
    return const Icon(Icons.login, size: 24);
  }
}

// Google Sign In Button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Logo
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomPaint(painter: GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Google Logo Painter
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    // Draw G shape (simplified)
    final center = Offset(width / 2, height / 2);
    final radius = width / 2.2;

    // Blue arc (right)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5,
      1.5,
      true,
      bluePaint,
    );

    // Green arc (bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.0,
      1.0,
      true,
      greenPaint,
    );

    // Yellow arc (left bottom)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.0,
      1.0,
      true,
      yellowPaint,
    );

    // Red arc (top)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.0,
      1.0,
      true,
      redPaint,
    );

    // White inner circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, whitePaint);

    // Blue rectangle for G opening
    canvas.drawRect(
      Rect.fromLTWH(width * 0.5, height * 0.35, width * 0.4, height * 0.3),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Phone Sign In Button
class PhoneSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const PhoneSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.phone_android,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Phone',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
