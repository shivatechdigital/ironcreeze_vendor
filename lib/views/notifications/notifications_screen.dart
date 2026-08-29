import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/firebase_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firebaseService = FirebaseService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(context, authProvider.user?.uid),
            child: Text(
              'Mark all read',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firebaseService.notificationsCollection
            .where('userId', isEqualTo: authProvider.user?.uid)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading notifications...');
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications =
              snapshot.data?.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList() ??
              [];

          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              message: 'You\'ll see notifications here when you receive them.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead(BuildContext context, String? userId) async {
    if (userId == null) return;

    final firebaseService = FirebaseService();
    final batch = FirebaseFirestore.instance.batch();

    final snapshot = await firebaseService.notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) async {
    // Mark as read
    if (!notification.isRead) {
      await FirebaseService().notificationsCollection
          .doc(notification.id)
          .update({'isRead': true});
    }

    // Navigate based on type
    if (notification.orderId != null) {
      // Navigate to order details
      // Navigator.pushNamed(context, AppRoutes.orderDetails, arguments: notification.orderId);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.orderNew:
        return Icons.shopping_bag_outlined;
      case NotificationType.orderAccepted:
        return Icons.check_circle_outline;
      case NotificationType.orderRejected:
        return Icons.cancel_outlined;
      case NotificationType.orderCompleted:
        return Icons.done_all;
      case NotificationType.accountApproved:
        return Icons.verified_outlined;
      case NotificationType.accountRejected:
        return Icons.block;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.orderNew:
        return AppColors.primary;
      case NotificationType.orderAccepted:
        return AppColors.success;
      case NotificationType.orderRejected:
      case NotificationType.accountRejected:
        return AppColors.error;
      case NotificationType.orderCompleted:
        return AppColors.success;
      case NotificationType.accountApproved:
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.white
              : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? AppColors.border
                : color.withOpacity(0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), color: color, size: 24),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.getRelativeTime(notification.createdAt),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
