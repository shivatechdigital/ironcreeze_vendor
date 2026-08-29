import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../data/models/customer_rating_summary.dart';
import '../../../providers/customer_review_provider.dart';

class CustomerRatingBadge extends StatefulWidget {
  final String customerId;
  final bool compact;

  const CustomerRatingBadge({
    super.key,
    required this.customerId,
    this.compact = false,
  });

  @override
  State<CustomerRatingBadge> createState() => _CustomerRatingBadgeState();
}

class _CustomerRatingBadgeState extends State<CustomerRatingBadge> {
  @override
  void initState() {
    super.initState();
    _fetchRating();
  }

  void _fetchRating() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<CustomerReviewProvider>();
        provider.fetchCustomerRating(widget.customerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerReviewProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoadingRating(widget.customerId);
        final summary = provider.getCachedRating(widget.customerId);

        if (isLoading && summary == null) {
          return _buildLoading();
        }

        if (summary == null || !summary.hasRatings) {
          return _buildNoRating();
        }

        return _buildRating(summary);
      },
    );
  }

  // ── Loading ──────────────────────────────────────────────────────
  Widget _buildLoading() {
    // compact mode me loading show na karo — space bachao
    if (widget.compact) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 40,
        height: 14,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(AppColors.grey300),
        ),
      ),
    );
  }

  // ── No Rating ────────────────────────────────────────────────────
  Widget _buildNoRating() {
    // compact = true → sirf star icon, no text
    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: 12,
              color: AppColors.grey400,
            ),
            const SizedBox(width: 3),
            Text(
              'New',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    // compact = false → full badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 14, color: AppColors.grey400),
          const SizedBox(width: 4),
          Text(
            'New',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.grey500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Has Rating ───────────────────────────────────────────────────
  Widget _buildRating(CustomerRatingSummary summary) {
    final Color ratingColor = _getRatingColor(summary.averageRating);

    // compact = true → small badge, no review count
    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: ratingColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ratingColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 12, color: ratingColor),
            const SizedBox(width: 3),
            Text(
              summary.displayRating,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ratingColor,
              ),
            ),
          ],
        ),
      );
    }

    // compact = false → full badge with review count
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ratingColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: ratingColor),
          const SizedBox(width: 4),
          Text(
            summary.displayRating,
            style: AppTextStyles.labelSmall.copyWith(
              color: ratingColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${summary.totalReviews})',
            style: AppTextStyles.labelSmall.copyWith(
              color: ratingColor.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return AppColors.success;
    if (rating >= 3.0) return AppColors.warning;
    return AppColors.error;
  }
}
