import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  // 1. NEW ORDER — customer ne order place kiya
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendNewOrderNotification({
    required String vendorId,
    required String orderId,
    required String orderShortId,
    required String customerName,
    required double total,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: orderId,
      type: 'order_new',
      title: 'New Order Received 🛒',
      body:
          '$customerName placed order #$orderShortId worth ₹${total.toStringAsFixed(0)}',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. ONLINE PAYMENT DONE
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendOnlinePaymentNotification({
    required String vendorId,
    required String orderId,
    required String orderShortId,
    required double amount,
    required String customerName,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: orderId,
      type: 'order_accepted',
      title: 'Online Payment Received 💳',
      body:
          '$customerName paid ₹${amount.toStringAsFixed(0)} online for order #$orderShortId',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. Order Accepted
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendOrderAcceptedNotification({
    required String vendorId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: orderId,
      type: 'order_accepted',
      title: 'Order Accepted ✅',
      body: 'You accepted order #$orderShortId successfully.',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. Order Completed
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendOrderCompletedNotification({
    required String vendorId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: orderId,
      type: 'order_completed',
      title: 'Order Completed 🎉',
      body: 'Order #$orderShortId delivered successfully!',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. Account Approved / Rejected
  // ═══════════════════════════════════════════════════════════════
  static Future<void> sendAccountApprovedNotification({
    required String vendorId,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: null,
      type: 'account_approved',
      title: 'Account Approved ✅',
      body: 'Your vendor account is approved. Start accepting orders!',
    );
  }

  static Future<void> sendAccountRejectedNotification({
    required String vendorId,
    String? reason,
  }) async {
    await _saveToFirestore(
      userId: vendorId,
      orderId: null,
      type: 'account_rejected',
      title: 'Account Rejected ❌',
      body: reason ?? 'Your vendor account application was not approved.',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 CUSTOMER NOTIFICATIONS — naye methods, existing code safe hai
  // ═══════════════════════════════════════════════════════════════

  static Future<void> notifyCustomerOrderAccepted({
    required String customerId,
    required String orderId,
    required String orderShortId,
    required String vendorName,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'order_accepted',
      title: 'Order Accepted ✅',
      message:
          'Your order #$orderShortId has been accepted by $vendorName! We\'ll pick it up soon.',
    );
  }

  static Future<void> notifyCustomerOrderRejected({
    required String customerId,
    required String orderId,
    required String orderShortId,
    required String vendorName,
    String? reason,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'order_rejected',
      title: 'Order Rejected ❌',
      message: reason != null
          ? 'Your order #$orderShortId was rejected. Reason: $reason'
          : 'Your order #$orderShortId was rejected by $vendorName.',
    );
  }

  static Future<void> notifyCustomerOrderPicked({
    required String customerId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'order_accepted',
      title: 'Order Picked Up 🧺',
      message:
          'Your clothes for order #$orderShortId have been picked up. We\'re working on them!',
    );
  }

  static Future<void> notifyCustomerOrderInProgress({
    required String customerId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'order_accepted',
      title: 'In Progress 🔄',
      message:
          'Your order #$orderShortId is being processed. We\'ll notify you when it\'s ready!',
    );
  }

  static Future<void> notifyCustomerReadyForDelivery({
    required String customerId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'ready_for_delivery',
      title: 'Out for Delivery 🚚',
      message: 'Your order #$orderShortId is ready and on its way to you!',
    );
  }

  static Future<void> notifyCustomerOrderDelivered({
    required String customerId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'ready_for_delivery',
      title: 'Delivery Started 🚪',
      message:
          'Your order #$orderShortId is being delivered. Please be available!',
    );
  }

  static Future<void> notifyCustomerOrderCompleted({
    required String customerId,
    required String orderId,
    required String orderShortId,
  }) async {
    await _saveCustomerNotification(
      customerId: customerId,
      orderId: orderId,
      type: 'order_completed',
      title: 'Order Completed 🎉',
      message:
          'Your order #$orderShortId has been delivered successfully. Thank you for using IronCreeze!',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Vendor Firestore core — existing, touch nahi kiya
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _saveToFirestore({
    required String userId,
    required String? orderId,
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      final notificationId = const Uuid().v4();
      await _firestore.collection('notifications').doc(notificationId).set({
        'userId': userId,
        'orderId': orderId,
        'type': type,
        'title': title,
        'body': body,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification saved: $type → $userId');
    } catch (e) {
      debugPrint('❌ Notification save error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔥 Customer Firestore core — naya method, existing safe hai
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _saveCustomerNotification({
    required String customerId,
    required String? orderId,
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      final notificationId = const Uuid().v4();
      await _firestore.collection('notifications').doc(notificationId).set({
        'customerId': customerId,
        'orderId': orderId,
        'type': type,
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Customer notification saved: $type → $customerId');
    } catch (e) {
      debugPrint('❌ Customer notification save error: $e');
    }
  }
}
