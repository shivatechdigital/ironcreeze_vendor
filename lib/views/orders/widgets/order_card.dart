import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcreze_vendor/views/orders/order_details_screen.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../core/enums/order_status.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../widgets/custom_button.dart';

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool showActions;

  const OrderCard({super.key, required this.order, this.showActions = true});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isLoading = false;

  // ── Main action handler ────────────────────────────────────────────────────
  Future<void> _handleAction() async {
    if (!mounted) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    switch (widget.order.status) {
      // ── Pickup code ──────────────────────────────────────────────────────
      case OrderStatus.accepted:
        final code = await _showCodeDialog(
          'Enter Pickup Code',
          'Ask customer for the 4-digit pickup code',
          AppColors.primary,
        );
        if (code == null || !mounted) return;

        setState(() => _isLoading = true);
        final pickSuccess = await orderProvider.markAsPicked(
          widget.order.orderId,
          code,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (pickSuccess) {
          Helpers.showSuccessToast('Order picked up!');
        } else {
          Helpers.showErrorToast(orderProvider.error ?? 'Invalid pickup code!');
        }
        break;

      // ── In Progress ──────────────────────────────────────────────────────
      case OrderStatus.picked:
        if (!mounted) return;
        setState(() => _isLoading = true);

        final progressSuccess = await orderProvider.markAsProgress(
          widget.order.orderId,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (progressSuccess) {
          Helpers.showSuccessToast('Order in progress!');
        } else {
          Helpers.showErrorToast(
            orderProvider.error ?? 'Failed to update order',
          );
        }
        break;

      // ── Ready for Delivery ────────────────────────────────────────────────
      case OrderStatus.progress:
        if (!mounted) return;
        setState(() => _isLoading = true);

        final readySuccess = await orderProvider.markAsReadyForDelivery(
          widget.order.orderId,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (readySuccess) {
          Helpers.showSuccessToast('Order ready for delivery!');
        } else {
          Helpers.showErrorToast(
            orderProvider.error ?? 'Failed to update order',
          );
        }
        break;

      // ── Out for Delivery ──────────────────────────────────────────────────
      case OrderStatus.readyForDelivery:
        if (!mounted) return;
        setState(() => _isLoading = true);

        final deliverySuccess = await orderProvider.markAsDelivery(
          widget.order.orderId,
        );
        if (!mounted) return;
        setState(() => _isLoading = false);

        if (deliverySuccess) {
          Helpers.showSuccessToast('Order out for delivery!');
        } else {
          Helpers.showErrorToast(
            orderProvider.error ?? 'Failed to update order',
          );
        }
        break;

      // ── delivery & completed — customer karega ────────────────────────────
      case OrderStatus.delivery:
      case OrderStatus.completed:
        break;

      default:
        break;
    }
  }

  // ── Generic Code Dialog ────────────────────────────────────────────────────
  Future<String?> _showCodeDialog(
    String title,
    String subtitle,
    Color color,
  ) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: AppTextStyles.heading6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading4.copyWith(letterSpacing: 8),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '• • • •',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                Navigator.pop(context, controller.text);
              } else {
                Helpers.showErrorToast('Please enter 4-digit code');
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  // ── Action Button Text ─────────────────────────────────────────────────────
  String _getActionButtonText() {
    switch (widget.order.status) {
      case OrderStatus.accepted:
        return 'Mark as Picked Up';
      case OrderStatus.picked:
        return 'Mark In Progress';
      case OrderStatus.progress:
        if (widget.order.items.isEmpty) return 'Open Order';
        return 'Mark Ready for Delivery';
      case OrderStatus.readyForDelivery:
        return 'Out for Delivery';
      // ✅ delivery & completed — customer karega, koi button nahi
      case OrderStatus.delivery:
      case OrderStatus.completed:
        return '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${widget.order.orderId.substring(0, 8).toUpperCase()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.order.customerName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // ── Details ──────────────────────────────────────────────────────
          _buildDetailRow(
            Icons.shopping_bag_outlined,
            '${widget.order.totalItems} items',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Pickup: ${DateFormatter.toDate(widget.order.pickupDate)}',
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.payments_outlined,
            Helpers.formatCurrency(widget.order.total),
          ),

          // ── Action Button ─────────────────────────────────────────────────
          // ✅ Sirf tab dikhao jab button text empty nahi ho
          if (widget.showActions && _getActionButtonText().isNotEmpty) ...[
            const SizedBox(height: 16),
            CustomButton(
              text: _getActionButtonText(),
              onPressed: () {
                // Progress + random order → open details screen
                if (widget.order.status == OrderStatus.progress &&
                    widget.order.items.isEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: widget.order),
                    ),
                  );
                  return;
                }
                _handleAction();
              },
              isLoading: _isLoading,
              size: ButtonSize.medium,
            ),
          ],
        ],
      ),
    );
  }

  // ── Status Badge ───────────────────────────────────────────────────────────
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.order.status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.order.status.displayName,
        style: AppTextStyles.labelSmall.copyWith(
          color: widget.order.status.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Detail Row ─────────────────────────────────────────────────────────────
  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.grey500),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
