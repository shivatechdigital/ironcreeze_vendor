import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VendorOrderCartScreen
// Cart review after vendor selects services.
// Shows items, subtotal, platform fee, total.
// On confirm → updates Firestore order → pops both screens with updatedOrder
// OrderDetailsScreen receives updated OrderModel instantly (no Firestore wait)
// ─────────────────────────────────────────────────────────────────────────────

class VendorOrderCartScreen extends StatefulWidget {
  final OrderModel order;
  final List<Map<String, dynamic>> selectedItems;

  const VendorOrderCartScreen({
    super.key,
    required this.order,
    required this.selectedItems,
  });

  @override
  State<VendorOrderCartScreen> createState() => _VendorOrderCartScreenState();
}

class _VendorOrderCartScreenState extends State<VendorOrderCartScreen> {
  late List<Map<String, dynamic>> _items;
  bool _isUpdating = false;

  static const _orange = Color(0xFFE8730F);

  @override
  void initState() {
    super.initState();
    // Deep copy so edits don't affect parent
    _items = widget.selectedItems
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // ── Computed totals ──────────────────────────────────────────────────────
  double get _subtotal =>
      _items.fold(0.0, (sum, item) => sum + (item['totalPrice'] as double));

  double get _platformFee =>
      double.parse((_subtotal * 0.10).toStringAsFixed(2));

  double get _total =>
      double.parse((_subtotal + _platformFee).toStringAsFixed(2));

  int get _totalQty =>
      _items.fold(0, (sum, item) => sum + (item['quantity'] as int));

  // ── Qty controls ─────────────────────────────────────────────────────────
  void _increment(int index) {
    setState(() {
      _items[index]['quantity'] = (_items[index]['quantity'] as int) + 1;
      _items[index]['totalPrice'] =
          (_items[index]['price'] as double) * _items[index]['quantity'];
    });
  }

  void _decrement(int index) {
    setState(() {
      final qty = (_items[index]['quantity'] as int) - 1;
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['quantity'] = qty;
        _items[index]['totalPrice'] = (_items[index]['price'] as double) * qty;
      }
    });
  }

  // ── Update order in Firestore ─────────────────────────────────────────────
  Future<void> _updateOrder() async {
    if (_items.isEmpty) {
      Helpers.showErrorToast('Please add at least one service');
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order.orderId)
          .update({
            'items': _items,
            'subtotal': _subtotal,
            'platformFee': _platformFee,
            'total': _total,
            // ✅ Do NOT update status here — OrderDetailsScreen handles it
          });

      setState(() => _isUpdating = false);
      Helpers.showSuccessToast('Items added to order!');

      if (mounted) {
        // ✅ Build updated OrderModel to pass back directly
        // This avoids a Firestore re-fetch in OrderDetailsScreen
        final updatedItems = _items.map((item) {
          return OrderItemModel(
            serviceId: item['serviceId'] as String? ?? '',
            name: item['name'] as String,
            price: item['price'] as double,
            quantity: item['quantity'] as int,
          );
        }).toList();

        final updatedOrder = widget.order.copyWith(
          items: updatedItems,
          subtotal: _subtotal,
          platformFee: _platformFee,
          total: _total,
        );

        // Pop cart screen (back to VendorAddItemsScreen)
        Navigator.pop(context);
        // Pop add-items screen, pass updated order to OrderDetailsScreen
        Navigator.pop(context, updatedOrder);
      }
    } catch (e) {
      setState(() => _isUpdating = false);
      Helpers.showErrorToast('Failed to update order. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Cart',
              style: AppTextStyles.heading6.copyWith(
                color: const Color(0xFF1A1A2E),
              ),
            ),
            Text(
              'Order #${widget.order.orderId.substring(0, 8).toUpperCase()}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Items List ─────────────────────────────────────────────────
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 48,
                          color: AppColors.grey300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items in cart',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Go back to add items'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final qty = item['quantity'] as int;
                      final price = item['price'] as double;
                      final totalPrice = item['totalPrice'] as double;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.dry_cleaning_outlined,
                                color: _orange,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Name + price per item
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${price.toStringAsFixed(2)} × $qty',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Total + qty control
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _orange,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  decoration: BoxDecoration(
                                    color: _orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _decrement(index),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 22,
                                        child: Text(
                                          '$qty',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _increment(index),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ── Summary + Update Button ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Summary card
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Total Items', '$_totalQty items'),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Subtotal',
                          '₹${_subtotal.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 6),
                        _summaryRow(
                          'Platform Fee (10%)',
                          '₹${_platformFee.toStringAsFixed(2)}',
                          isLight: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        _summaryRow(
                          'Total',
                          '₹${_total.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  // Update Order button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isUpdating || _items.isEmpty
                          ? null
                          : _updateOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        disabledBackgroundColor: _orange.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Update Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    bool isLight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isLight ? AppColors.textSecondary : const Color(0xFF1A1A2E),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isBold ? _orange : const Color(0xFF1A1A2E),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            fontSize: isBold ? 17 : 14,
          ),
        ),
      ],
    );
  }
}
