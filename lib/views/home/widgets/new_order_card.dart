import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../widgets/custom_button.dart';
import 'customer_rating_badge.dart';

class NewOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final bool isLoading;

  const NewOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onTap,
    this.isLoading = false,
  });

  bool get _isRandomOrder => order.total == 0 && order.items.isEmpty;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ───────────────────────────────────────────
            _buildHeader(),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // ── Order Details ─────────────────────────────────────────
            _buildDetailRow(
              icon: Icons.shopping_bag_outlined,
              label: 'Items',
              value: _isRandomOrder
                  ? 'Random order - items to be decided'
                  : '${order.totalItems} Items (${order.items.map((i) => '${i.name} x${i.quantity}').join(', ')})',
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Pickup',
              value: DateFormatter.toDate(order.pickupDate),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: '${order.customerCity} - ${order.customerPinCode}',
            ),

            const SizedBox(height: 20),

            // ── Action Buttons ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reject',
                    onPressed: isLoading ? null : onReject,
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                    textColor: AppColors.error,
                    borderRadius: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Accept',
                    onPressed: isLoading ? null : onAccept,
                    type: ButtonType.primary,
                    size: ButtonSize.medium,
                    isLoading: isLoading,
                    borderRadius: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER — Avatar + Name/Rating/Time + Amount
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Avatar ────────────────────────────────────────────────
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              Helpers.getInitials(order.customerName),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // ── Name + Rating + Time ──────────────────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name + Rating in one row
              // Name = flexible (ellipsis), Rating = fixed (never wraps)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Name — takes available space, cuts if too long
                  Flexible(
                    child: Text(
                      order.customerName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Rating badge — fixed size
                  CustomerRatingBadge(
                    customerId: order.customerId,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Time
              Text(
                DateFormatter.getRelativeTime(order.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // ── Amount Badge — right side, fixed max width ────────────
        _buildAmountBadge(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AMOUNT BADGE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAmountBadge() {
    if (_isRandomOrder) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8730F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shuffle_rounded,
              size: 14,
              color: Color(0xFFE8730F),
            ),
            const SizedBox(width: 4),
            Text(
              'Random',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFFE8730F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Price badge — FittedBox handles any amount (₹22 to ₹1,000,000)
    return Container(
      constraints: const BoxConstraints(minWidth: 60, maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          Helpers.formatCurrency(order.total),
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DETAIL ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
