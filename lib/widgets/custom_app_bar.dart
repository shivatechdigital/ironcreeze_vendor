import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.heading6.copyWith(
                    color: foregroundColor ?? AppColors.textPrimary,
                  ),
                )
              : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.white,
      foregroundColor: foregroundColor ?? AppColors.textPrimary,
      elevation: elevation,
      surfaceTintColor: AppColors.white,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: foregroundColor ?? AppColors.textPrimary,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
    );
  }
}
