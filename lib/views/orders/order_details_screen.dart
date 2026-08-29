import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcreze_vendor/services/vendor_add_items_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/enums/order_status.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/services/firebase_service.dart' hide debugPrint;
import '../../providers/order_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/confirmation_dialog.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = false;
  late OrderModel _order;

  // ✅ Firestore real-time listener
  late Stream<DocumentSnapshot> _orderStream;

  bool get _isRandomOrder => _order.total == 0 && _order.items.isEmpty;

  @override
  void initState() {
    super.initState();
    _order = widget.order;

    // ✅ Real-time stream — order document ko listen karo
    _orderStream = FirebaseService().ordersCollection
        .doc(widget.order.orderId)
        .snapshots();
  }

  Future<void> _callCustomer() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: _order.customerPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  // ── Main status handler ───────────────────────────────────────────────────
  Future<void> _handleStatusUpdate(OrderStatus newStatus) async {
    if (!mounted) return;
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // ── Picked ────────────────────────────────────────────────────────────
    if (newStatus == OrderStatus.picked) {
      final pickupCode = await _showCodeInputDialog(
        'Enter Pickup Code',
        'Ask customer for their 4-digit pickup code',
      );
      if (pickupCode == null || !mounted) return;

      setState(() => _isLoading = true);
      final success = await orderProvider.markAsPicked(
        _order.orderId,
        pickupCode,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        Helpers.showSuccessToast('Order picked up!');
        // ✅ Stream automatically update karega — no manual setState needed
      } else {
        Helpers.showErrorToast(orderProvider.error ?? 'Invalid pickup code!');
      }
      return;
    }

    // ── Ready for Delivery ────────────────────────────────────────────────
    if (newStatus == OrderStatus.readyForDelivery) {
      if (_isRandomOrder) {
        final updatedOrder = await Navigator.push<OrderModel>(
          context,
          MaterialPageRoute(
            builder: (_) => VendorAddItemsScreen(order: _order),
          ),
        );

        if (updatedOrder != null && mounted) {
          setState(() => _order = updatedOrder);
          await _markReadyForDelivery();
        }
        return;
      }

      await _markReadyForDelivery();
      return;
    }

    // ── Other status updates ──────────────────────────────────────────────
    if (!mounted) return;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Update Status',
      message: 'Change order status to "${newStatus.displayName}"?',
      confirmText: 'Update',
      cancelText: 'Cancel',
      icon: Icons.update,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    bool success = false;

    switch (newStatus) {
      case OrderStatus.progress:
        success = await orderProvider.markAsProgress(_order.orderId);
        break;
      case OrderStatus.delivery:
        success = await orderProvider.markAsDelivery(_order.orderId);
        break;
      default:
        break;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccessToast('Status updated!');
      // ✅ Stream automatically update karega
    } else {
      Helpers.showErrorToast(orderProvider.error ?? 'Failed to update status');
    }
  }

  Future<void> _markReadyForDelivery() async {
    if (!mounted) return;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Mark Ready for Delivery',
      message: 'Mark this order as ready for delivery?',
      confirmText: 'Confirm',
      cancelText: 'Cancel',
      icon: Icons.local_shipping_outlined,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.markAsReadyForDelivery(_order.orderId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Helpers.showSuccessToast('Order marked ready for delivery!');
      // ✅ Stream automatically update karega
    } else {
      Helpers.showErrorToast(orderProvider.error ?? 'Failed to update status');
    }
  }

  Future<String?> _showCodeInputDialog(String title, String subtitle) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: AppTextStyles.heading4,
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

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ✅ StreamBuilder wrap karo — real-time updates milenge
    return StreamBuilder<DocumentSnapshot>(
      stream: _orderStream,
      builder: (context, snapshot) {
        // ✅ Firestore se naya data aane pe _order update karo
        if (snapshot.hasData && snapshot.data!.exists) {
          _order = OrderModel.fromFirestore(snapshot.data!);
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Order Details',
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: _callCustomer,
                icon: const Icon(Icons.call, color: AppColors.success),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Customer Details',
                  child: _buildCustomerInfo(),
                ),
                const SizedBox(height: 20),
                _buildSection(title: 'Order Items', child: _buildOrderItems()),
                const SizedBox(height: 20),
                _buildSection(
                  title: 'Price Details',
                  child: _buildPriceDetails(),
                ),
                const SizedBox(height: 20),
                _buildSection(title: 'Schedule', child: _buildSchedule()),
                const SizedBox(height: 20),
                _buildSection(title: 'Order Timeline', child: _buildTimeline()),
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(),
        );
      },
    );
  }

  // ── Order Header ───────────────────────────────────────────────────────────
  Widget _buildOrderHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '#${_order.orderId.substring(0, 8).toUpperCase()}',
                    style: AppTextStyles.heading5,
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _order.orderId));
                      Helpers.showToast('Order ID copied!');
                    },
                    child: const Icon(
                      Icons.copy,
                      size: 16,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isRandomOrder)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8730F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shuffle_rounded,
                    size: 14,
                    color: Color(0xFFE8730F),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Random',
                    style: TextStyle(
                      color: Color(0xFFE8730F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _order.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _order.status.displayName,
                style: AppTextStyles.labelMedium.copyWith(
                  color: _order.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section Wrapper ────────────────────────────────────────────────────────
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }

  // ── Customer Info ──────────────────────────────────────────────────────────
  Widget _buildCustomerInfo() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  Helpers.getInitials(_order.customerName),
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _order.customerName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _order.customerPhone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _callCustomer,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.call,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppColors.grey500,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_order.customerAddress}, ${_order.customerCity} - ${_order.customerPinCode}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Order Items ────────────────────────────────────────────────────────────
  Widget _buildOrderItems() {
    if (_isRandomOrder) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                Icons.shuffle_rounded,
                size: 40,
                color: const Color(0xFFE8730F).withOpacity(0.35),
              ),
              const SizedBox(height: 10),
              Text(
                'Random order',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE8730F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Services will be added by vendor',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _order.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('👕', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${Helpers.formatCurrency(item.price)} × ${item.quantity}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Helpers.formatCurrency(item.totalPrice),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Price Details ──────────────────────────────────────────────────────────
  Widget _buildPriceDetails() {
    return Column(
      children: [
        _buildPriceRow('Subtotal', _order.subtotal),
        const SizedBox(height: 8),
        _buildPriceRow('Platform Fee', _order.platformFee),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        _buildPriceRow('Total', _order.total, isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    final displayValue = _isRandomOrder
        ? 'TBD'
        : Helpers.formatCurrency(amount);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          displayValue,
          style: isTotal
              ? AppTextStyles.heading5.copyWith(
                  color: _isRandomOrder
                      ? AppColors.textSecondary
                      : AppColors.success,
                )
              : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Schedule ───────────────────────────────────────────────────────────────
  Widget _buildSchedule() {
    return Column(
      children: [
        _buildScheduleRow(
          icon: Icons.calendar_today_outlined,
          label: 'Pickup Date',
          value: DateFormatter.toFullDate(_order.pickupDate),
        ),
        if (_order.deliveryDate != null) ...[
          const SizedBox(height: 12),
          _buildScheduleRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery Date',
            value: DateFormatter.toFullDate(_order.deliveryDate),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────
  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          title: 'Order Placed',
          time: _order.createdAt,
          isCompleted: true,
          isFirst: true,
          // ✅ last check — agar koi aur event nahi hai
          isLast:
              _order.acceptedAt == null &&
              _order.pickedAt == null &&
              _order.progressAt == null &&
              _order.readyForDeliveryAt == null &&
              _order.deliveryAt == null &&
              _order.completedAt == null &&
              _order.rejectedAt == null,
        ),
        if (_order.acceptedAt != null)
          _buildTimelineItem(
            title: 'Order Accepted',
            time: _order.acceptedAt!,
            isCompleted: true,
            isLast:
                _order.pickedAt == null &&
                _order.progressAt == null &&
                _order.readyForDeliveryAt == null &&
                _order.deliveryAt == null &&
                _order.completedAt == null &&
                _order.rejectedAt == null,
          ),
        if (_order.pickedAt != null)
          _buildTimelineItem(
            title: 'Picked Up',
            time: _order.pickedAt!,
            isCompleted: true,
            isLast:
                _order.progressAt == null &&
                _order.readyForDeliveryAt == null &&
                _order.deliveryAt == null &&
                _order.completedAt == null &&
                _order.rejectedAt == null,
          ),
        if (_order.progressAt != null)
          _buildTimelineItem(
            title: 'In Progress',
            time: _order.progressAt!,
            isCompleted: true,
            isLast:
                _order.readyForDeliveryAt == null &&
                _order.deliveryAt == null &&
                _order.completedAt == null &&
                _order.rejectedAt == null,
          ),
        if (_order.readyForDeliveryAt != null)
          _buildTimelineItem(
            title: 'Ready for Delivery',
            time: _order.readyForDeliveryAt!,
            isCompleted: true,
            isLast:
                _order.deliveryAt == null &&
                _order.completedAt == null &&
                _order.rejectedAt == null,
          ),
        if (_order.deliveryAt != null)
          _buildTimelineItem(
            title: 'Out for Delivery',
            time: _order.deliveryAt!,
            isCompleted: true,
            isLast: _order.completedAt == null && _order.rejectedAt == null,
          ),
        if (_order.completedAt != null)
          _buildTimelineItem(
            title: 'Completed',
            time: _order.completedAt!,
            isCompleted: true,
            isLast: true,
          ),
        if (_order.rejectedAt != null)
          _buildTimelineItem(
            title: 'Rejected',
            time: _order.rejectedAt!,
            isCompleted: true,
            isLast: true,
            isError: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required DateTime time,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
    bool isError = false,
  }) {
    final color = isError ? AppColors.error : AppColors.success;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? color : AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 14,
                color: AppColors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? color : AppColors.grey200,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isError ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormatter.toDateTime(time),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom Action ──────────────────────────────────────────────────────────
  Widget? _buildBottomAction() {
    String? buttonText;
    OrderStatus? nextStatus;

    switch (_order.status) {
      case OrderStatus.accepted:
        buttonText = 'Mark as Picked Up';
        nextStatus = OrderStatus.picked;
        break;
      case OrderStatus.picked:
        buttonText = 'Mark In Progress';
        nextStatus = OrderStatus.progress;
        break;
      case OrderStatus.progress:
        buttonText = _isRandomOrder ? 'Add Items' : 'Mark Ready for Delivery';
        nextStatus = OrderStatus.readyForDelivery;
        break;
      case OrderStatus.readyForDelivery:
        buttonText = 'Mark Out for Delivery';
        nextStatus = OrderStatus.delivery;
        break;

      // ✅ koi button nahi
      case OrderStatus.delivery:
      case OrderStatus.completed:
        return null;

      default:
        return null;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: buttonText,
          onPressed: () => _handleStatusUpdate(nextStatus!),
          isLoading: _isLoading,
        ),
      ),
    );
  }
}
