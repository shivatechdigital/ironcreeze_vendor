import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';

class OrderTabs extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> tabs;

  const OrderTabs({super.key, required this.controller, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: TabBar(
        controller: controller,
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );
  }
}
