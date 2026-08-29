import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/vendor_model.dart';
import '../../../providers/profile_provider.dart';

class VendorHeader extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback? onProfileTap;

  const VendorHeader({super.key, required this.vendor, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Profile Picture ──────────────────────────────────────
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: ClipOval(
              child: vendor.profileImage != null
                  ? CachedNetworkImage(
                      imageUrl: vendor.profileImage!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Name & Rating ────────────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: AppTextStyles.heading6,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ✅ ProfileProvider se real rating lo
              Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final rating = profileProvider.totalReviews > 0
                      ? profileProvider.rating
                      : 0.0;

                  final completedOrders = profileProvider.totalCompletedOrders;

                  return Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),

                      // Rating value
                      profileProvider.isLoading
                          ? _buildLoadingChip(width: 28)
                          : Text(
                              rating.toStringAsFixed(1),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.grey400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Orders count
                      profileProvider.isLoading
                          ? _buildLoadingChip(width: 50)
                          : Text(
                              '$completedOrders orders',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Loading Chip ─────────────────────────────────────────────
  Widget _buildLoadingChip({required double width}) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primaryBackground,
      child: Center(
        child: Text(
          Helpers.getInitials(vendor.name),
          style: AppTextStyles.heading5.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
