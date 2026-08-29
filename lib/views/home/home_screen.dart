// lib/views/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:ironcreze_vendor/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/customer_review_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/confirmation_dialog.dart';
import 'widgets/vendor_header.dart';
import 'widgets/online_toggle.dart';
import 'widgets/stats_card.dart';
import 'widgets/new_order_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTogglingOnline = false;
  String? _processingOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchCustomerRatings();
      _loadProfileStats(); // ✅ add this
    });
  }

  void _loadProfileStats() {
    final vendorId = Provider.of<VendorProvider>(
      context,
      listen: false,
    ).vendor?.uid;
    if (vendorId != null) {
      Provider.of<ProfileProvider>(
        context,
        listen: false,
      ).fetchProfileStats(vendorId);
    }
  }

  void _prefetchCustomerRatings() {
    final orderProvider = context.read<OrderProvider>();
    final reviewProvider = context.read<CustomerReviewProvider>();

    if (orderProvider.newOrders.isNotEmpty) {
      final customerIds = orderProvider.newOrders
          .map((o) => o.customerId)
          .toSet()
          .toList();
      reviewProvider.fetchRatingsForCustomers(customerIds);
    }
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isTogglingOnline = true);

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final success = await vendorProvider.toggleOnlineStatus();

    if (!mounted) return;
    setState(() => _isTogglingOnline = false);

    if (success) {
      Helpers.showSuccessToast(
        vendorProvider.isOnline ? 'You are now online!' : 'You are now offline',
      );
    } else {
      Helpers.showErrorToast('Failed to update status');
    }
  }

  Future<void> _handleAcceptOrder(String orderId) async {
    if (_processingOrderId != null) return;

    setState(() => _processingOrderId = orderId);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.acceptOrder(orderId);

    if (!mounted) return;
    setState(() => _processingOrderId = null);

    if (success) {
      Helpers.showSuccessToast('Order accepted!');
    } else {
      Helpers.showErrorToast(orderProvider.error ?? 'Failed to accept order');
    }
  }

  Future<void> _handleRejectOrder(String orderId) async {
    if (_processingOrderId != null) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Reject Order?',
      message:
          'Are you sure you want to reject this order? The customer will be notified.',
      confirmText: 'Reject',
      cancelText: 'Cancel',
      confirmColor: AppColors.error,
      icon: Icons.cancel_outlined,
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _processingOrderId = orderId);

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final success = await orderProvider.rejectOrder(orderId);

    if (!mounted) return;

    setState(() => _processingOrderId = null);

    if (success) {
      Helpers.showToast('Order rejected');
    } else {
      Helpers.showErrorToast(orderProvider.error ?? 'Failed to reject order');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer3<VendorProvider, OrderProvider, CustomerReviewProvider>(
          builder: (context, vendorProvider, orderProvider, reviewProvider, child) {
            if (vendorProvider.state == VendorState.loading) {
              return const LoadingWidget(message: 'Loading...');
            }

            final vendor = vendorProvider.vendor;
            if (vendor == null) {
              return const Center(child: Text('Failed to load vendor data'));
            }

            // ✅ Pre-fetch ratings when new orders change
            if (orderProvider.newOrders.isNotEmpty) {
              final customerIds = orderProvider.newOrders
                  .map((o) => o.customerId)
                  .toSet()
                  .toList();

              // Use microtask to avoid calling during build
              Future.microtask(() {
                reviewProvider.fetchRatingsForCustomers(customerIds);
              });
            }

            return RefreshIndicator(
              onRefresh: () async {
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                if (authProvider.user != null) {
                  await vendorProvider.fetchVendor(authProvider.user!.uid);
                  await orderProvider.fetchOrders(authProvider.user!.uid);
                  // Refresh ratings cache too
                  if (orderProvider.newOrders.isNotEmpty) {
                    final customerIds = orderProvider.newOrders
                        .map((o) => o.customerId)
                        .toSet()
                        .toList();
                    await reviewProvider.fetchRatingsForCustomers(customerIds);
                  }
                }
              },
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: VendorHeader(vendor: vendor)),
                              const SizedBox(width: 16),
                              OnlineToggle(
                                isOnline: vendor.isOnline,
                                isLoading: _isTogglingOnline,
                                onChanged: (_) => _toggleOnlineStatus(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Greeting
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormatter.getGreeting(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Here's your summary for today",
                                  style: AppTextStyles.heading5,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Stats Cards
                          Row(
                            children: [
                              Expanded(
                                child: StatsCard(
                                  title: "Today's Earnings",
                                  value: orderProvider.todayEarnings.toString(),
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: AppColors.success,
                                  isCurrency: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatsCard(
                                  title: 'Completed Orders',
                                  value: orderProvider.todayCompletedOrders
                                      .toString(),
                                  icon: Icons.check_circle_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // New Orders Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('New Orders', style: AppTextStyles.heading6),
                              if (orderProvider.newOrders.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    orderProvider.newOrders.length.toString(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (orderProvider.newOrders.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                // Navigate to orders tab
                              },
                              child: Text(
                                'See All',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // New Orders List
                  if (orderProvider.newOrders.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: EmptyStateWidget(
                          icon: Icons.inbox_outlined,
                          title: 'No New Orders',
                          message: vendor.isOnline
                              ? 'New orders will appear here when customers place them.'
                              : 'Go online to start receiving orders.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final order = orderProvider.newOrders[index];
                          return NewOrderCard(
                            order: order,
                            isLoading: _processingOrderId == order.orderId,
                            onAccept: () => _handleAcceptOrder(order.orderId),
                            onReject: () => _handleRejectOrder(order.orderId),
                          );
                        }, childCount: orderProvider.newOrders.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
