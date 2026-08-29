import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../providers/service_provider.dart';
import 'vendor_order_cart_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VendorAddItemsScreen
// Opens when vendor taps "Add Items" on a Random order (total == 0)
// Vendor selects services → proceeds to VendorOrderCartScreen
// On cart confirm → receives updated OrderModel → pops with it to OrderDetailsScreen
// ─────────────────────────────────────────────────────────────────────────────

class VendorAddItemsScreen extends StatefulWidget {
  final OrderModel order;

  const VendorAddItemsScreen({super.key, required this.order});

  @override
  State<VendorAddItemsScreen> createState() => _VendorAddItemsScreenState();
}

class _VendorAddItemsScreenState extends State<VendorAddItemsScreen> {
  // serviceId → qty selected
  final Map<String, int> _qty = {};

  static const _orange = Color(0xFFE8730F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().fetchVendorServices(
        widget.order.vendorId,
      );
    });
  }

  bool get _hasSelection => _qty.values.any((q) => q > 0);

  int get _totalSelectedItems => _qty.values.fold(0, (sum, qty) => sum + qty);

  // ✅ Now async — awaits cart result and bubbles updated OrderModel up
  Future<void> _proceedToCart() async {
    if (!_hasSelection) {
      Helpers.showErrorToast('Please select at least one service');
      return;
    }

    final serviceProvider = context.read<ServiceProvider>();
    final List<Map<String, dynamic>> selectedItems = [];

    for (final service in serviceProvider.vendorServices) {
      final qty = _qty[service.serviceId] ?? 0;
      if (qty > 0) {
        selectedItems.add({
          'serviceId': service.serviceId,
          'name': service.name,
          'price': service.price,
          'quantity': qty,
          'totalPrice': service.price * qty,
        });
      }
    }

    // ✅ Await the cart screen — it returns the updated OrderModel on confirm
    final updatedOrder = await Navigator.push<OrderModel>(
      context,
      MaterialPageRoute(
        builder: (_) => VendorOrderCartScreen(
          order: widget.order,
          selectedItems: selectedItems,
        ),
      ),
    );

    // ✅ If cart confirmed and returned updated order, bubble it up to OrderDetailsScreen
    if (updatedOrder != null && mounted) {
      Navigator.pop(context, updatedOrder);
    }
    // If user cancelled cart (back button), stay on this screen — do nothing
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
              'Add Items',
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
      body: Consumer<ServiceProvider>(
        builder: (context, serviceProvider, _) {
          if (serviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = serviceProvider.vendorServices
              .where((s) => s.isActive)
              .toList();

          return Column(
            children: [
              // ── Info Banner ────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shuffle_rounded, color: _orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Customer placed a Random order. Select services you will provide.',
                        style: AppTextStyles.bodySmall.copyWith(color: _orange),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Services List ──────────────────────────────────────────
              Expanded(
                child: services.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.design_services_outlined,
                              size: 48,
                              color: AppColors.grey300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No active services found',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: services.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final service = services[index];
                          final qty = _qty[service.serviceId] ?? 0;

                          return _ServiceTile(
                            name: service.name,
                            price: service.price,
                            qty: qty,
                            isSelected: qty > 0,
                            onAdd: () =>
                                setState(() => _qty[service.serviceId] = 1),
                            onIncrement: () => setState(
                              () => _qty[service.serviceId] = qty + 1,
                            ),
                            onDecrement: () => setState(() {
                              if (qty > 1) {
                                _qty[service.serviceId] = qty - 1;
                              } else {
                                _qty.remove(service.serviceId);
                              }
                            }),
                          );
                        },
                      ),
              ),

              // ── Proceed Button ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                      if (_hasSelection)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart_outlined,
                                size: 16,
                                color: _orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_totalSelectedItems item(s) selected',
                                style: const TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _hasSelection ? _proceedToCart : null,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Proceed to Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            disabledBackgroundColor: _orange.withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ServiceTile
// ─────────────────────────────────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final String name;
  final double price;
  final int qty;
  final bool isSelected;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ServiceTile({
    required this.name,
    required this.price,
    required this.qty,
    required this.isSelected,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  static const _orange = Color(0xFFE8730F);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(color: _orange.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? _orange.withOpacity(0.1) : AppColors.grey100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.dry_cleaning_outlined,
              color: isSelected ? _orange : AppColors.grey400,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹${price.toStringAsFixed(2)} / item',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                ),
              ],
            ),
          ),
          if (qty == 0)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onDecrement,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(Icons.remove, color: Colors.white, size: 16),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onIncrement,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
