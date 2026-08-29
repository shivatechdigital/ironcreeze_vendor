import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderNew('order_new', 'New Order'),
  orderAccepted('order_accepted', 'Order Accepted'),
  orderRejected('order_rejected', 'Order Rejected'),
  orderCompleted('order_completed', 'Order Completed'),
  accountApproved('account_approved', 'Account Approved'),
  accountRejected('account_rejected', 'Account Rejected'),
  general('general', 'General');

  final String value;
  final String displayName;

  const NotificationType(this.value, this.displayName);

  static NotificationType fromString(String type) {
    return NotificationType.values.firstWhere(
      (e) => e.value == type.toLowerCase(),
      orElse: () => NotificationType.general,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: NotificationType.fromString(data['type'] ?? 'general'),
      orderId: data['orderId'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'orderId': orderId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
