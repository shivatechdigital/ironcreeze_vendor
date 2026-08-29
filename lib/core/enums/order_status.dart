import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

enum OrderStatus {
  requested('requested', 'Requested', AppColors.statusPending),
  accepted('accepted', 'Accepted', AppColors.statusAccepted),
  rejected('rejected', 'Rejected', AppColors.statusRejected),
  picked('picked', 'Picked Up', AppColors.statusPicked),
  progress('progress', 'In Progress', AppColors.statusProgress),
  readyForDelivery(
    'ready_for_delivery',
    'Ready for Delivery',
    Colors.indigo,
  ), // ✅ NEW
  delivery('delivery', 'Out for Delivery', AppColors.statusDelivery),
  completed('completed', 'Completed', AppColors.statusCompleted);

  final String value;
  final String displayName;
  final Color color;

  const OrderStatus(this.value, this.displayName, this.color);

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == status.toLowerCase(),
      orElse: () => OrderStatus.requested,
    );
  }
}
