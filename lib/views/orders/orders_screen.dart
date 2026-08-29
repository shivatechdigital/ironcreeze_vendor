import 'package:flutter/material.dart';
import 'package:ironcreze_vendor/views/orders/order_details_screen.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/order_provider.dart';
import '../../widgets/empty_state_widget.dart';
import 'widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Accepted', // 0
    'Pickup', // 1
    'Progress', // 2
    'Ready', // 3 ✅ NEW
    'Delivery', // 4
    'Completed', // 5
    'Rejected', // 6
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _getOrdersForTab(OrderProvider provider, int index) {
    switch (index) {
      case 0:
        return provider.acceptedOrders;
      case 1:
        return provider.pickedOrders;
      case 2:
        return provider.progressOrders;
      case 3:
        return provider.readyForDeliveryOrders; // ✅ NEW
      case 4:
        return provider.deliveryOrders;
      case 5:
        return provider.completedOrders;
      case 6:
        return provider.rejectedOrders;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Orders', style: AppTextStyles.heading5),
        centerTitle: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.labelMedium,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (index) {
              final orders = _getOrdersForTab(orderProvider, index);

              if (orders.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Orders',
                  message: 'No orders in this category yet.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(order: orders[i]),
                        ),
                      );
                    },
                    child: OrderCard(
                      order: orders[i],
                      // 0,1,2,3,4 = accepted/pickup/progress/ready/delivery
                      showActions: index < 5, // ✅ pehle < 4 tha
                    ),
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
