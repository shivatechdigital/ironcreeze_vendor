import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/order_model.dart';
import '../data/services/firebase_service.dart' hide debugPrint;
import '../core/enums/order_status.dart';
import '../services/notification_service.dart';
import '../services/local_notification_service.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  StreamSubscription? _ordersSubscription;

  List<OrderModel> _allOrders = [];
  List<OrderModel> get allOrders => _allOrders;

  List<OrderModel> _newOrders = [];
  List<OrderModel> get newOrders => _newOrders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  double _todayEarnings = 0;
  double get todayEarnings => _todayEarnings;

  int _todayCompletedOrders = 0;
  int get todayCompletedOrders => _todayCompletedOrders;

  final Set<String> _processingOrderIds = {};
  final Set<String> _notifiedNewOrders = {};
  final Set<String> _notifiedOnlinePayments = {};

  List<OrderModel> get requestedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.requested).toList();
  List<OrderModel> get acceptedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.accepted).toList();
  List<OrderModel> get pickedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.picked).toList();
  List<OrderModel> get progressOrders =>
      _allOrders.where((o) => o.status == OrderStatus.progress).toList();
  List<OrderModel> get readyForDeliveryOrders => _allOrders
      .where((o) => o.status == OrderStatus.readyForDelivery)
      .toList();
  List<OrderModel> get deliveryOrders =>
      _allOrders.where((o) => o.status == OrderStatus.delivery).toList();
  List<OrderModel> get completedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.completed).toList();
  List<OrderModel> get rejectedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.rejected).toList();

  Future<void> fetchOrders(String vendorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firebaseService.ordersCollection
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('createdAt', descending: true)
          .get();

      _allOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      _newOrders = _allOrders
          .where((o) => o.status == OrderStatus.requested)
          .toList();

      for (final order in _allOrders) {
        _notifiedNewOrders.add(order.orderId);
        if (_isOnlinePaymentDone(order)) {
          _notifiedOnlinePayments.add(order.orderId);
        }
      }

      _calculateTodayStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Fetch orders error: $e');
      _error = 'Failed to fetch orders';
      _isLoading = false;
      notifyListeners();
    }
  }

  void listenToOrders(String vendorId) {
    _ordersSubscription?.cancel();

    _ordersSubscription = _firebaseService.ordersCollection
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint('📡 Listener fired: ${snapshot.docs.length} orders');

            final updatedOrders = snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList();

            for (final order in updatedOrders) {
              if (order.status == OrderStatus.requested &&
                  !_notifiedNewOrders.contains(order.orderId) &&
                  !_processingOrderIds.contains(order.orderId)) {
                _notifiedNewOrders.add(order.orderId);
                _fireNewOrderNotification(vendorId, order);
              }
            }

            for (final order in updatedOrders) {
              if (_isOnlinePaymentDone(order) &&
                  !_notifiedOnlinePayments.contains(order.orderId)) {
                _notifiedOnlinePayments.add(order.orderId);
                _fireOnlinePaymentNotification(vendorId, order);
              }
            }

            _allOrders = updatedOrders;
            _newOrders = _allOrders
                .where(
                  (o) =>
                      o.status == OrderStatus.requested &&
                      !_processingOrderIds.contains(o.orderId),
                )
                .toList();

            _calculateTodayStats();
            notifyListeners();
          },
          onError: (e) {
            debugPrint('❌ Listen orders error: $e');
            _error = 'Real-time updates failed';
            notifyListeners();
          },
        );
  }

  bool _isOnlinePaymentDone(OrderModel order) {
    return order.paymentMethod == PaymentMethod.online &&
        order.paymentStatus == PaymentStatus.completed;
  }

  Future<void> _fireNewOrderNotification(
    String vendorId,
    OrderModel order,
  ) async {
    debugPrint(
      '🔔 New order detected: ${order.orderId} from ${order.customerName}',
    );

    await NotificationService.sendNewOrderNotification(
      vendorId: vendorId,
      orderId: order.orderId,
      orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      customerName: order.customerName,
      total: order.total,
    );

    await LocalNotificationService.showSimpleNotification(
      title: '🛒 New Order Received!',
      body:
          '${order.customerName} placed an order worth ₹${order.total.toStringAsFixed(0)}',
      payload: order.orderId,
    );
  }

  Future<void> _fireOnlinePaymentNotification(
    String vendorId,
    OrderModel order,
  ) async {
    debugPrint(
      '💳 Online payment detected: ${order.orderId} — ₹${order.total}',
    );

    await NotificationService.sendOnlinePaymentNotification(
      vendorId: vendorId,
      orderId: order.orderId,
      orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      amount: order.total,
      customerName: order.customerName,
    );

    await LocalNotificationService.showSimpleNotification(
      title: '💳 Online Payment Received!',
      body:
          '${order.customerName} paid ₹${order.total.toStringAsFixed(0)} for order #${order.orderId.substring(0, 8).toUpperCase()}',
      payload: order.orderId,
    );
  }

  void _calculateTodayStats() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final todayCompleted = _allOrders.where(
      (order) =>
          order.status == OrderStatus.completed &&
          order.completedAt != null &&
          order.completedAt!.isAfter(startOfDay),
    );

    _todayCompletedOrders = todayCompleted.length;
    _todayEarnings = todayCompleted.fold(0, (sum, order) => sum + order.total);
  }

  // ── Accept Order ──────────────────────────────────────────────────────────
  Future<bool> acceptOrder(String orderId) async {
    if (_processingOrderIds.contains(orderId)) return false;

    try {
      _processingOrderIds.add(orderId);
      notifyListeners();

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.accepted.value,
        'acceptedAt': Timestamp.now(),
      });

      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      // Vendor notification (existing)
      await NotificationService.sendOrderAcceptedNotification(
        vendorId: order.vendorId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderAccepted(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
        vendorName: order.vendorName,
      );

      await Future.delayed(const Duration(milliseconds: 500));
      _processingOrderIds.remove(orderId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Accept order error: $e');
      _error = 'Failed to accept order: ${e.toString()}';
      _processingOrderIds.remove(orderId);
      notifyListeners();
      return false;
    }
  }

  // ── Reject Order ──────────────────────────────────────────────────────────
  Future<bool> rejectOrder(String orderId, {String? reason}) async {
    if (_processingOrderIds.contains(orderId)) return false;

    try {
      _processingOrderIds.add(orderId);
      _newOrders.removeWhere((o) => o.orderId == orderId);
      notifyListeners();

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.rejected.value,
        'rejectedAt': Timestamp.now(),
        if (reason != null) 'rejectionReason': reason,
      });

      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderRejected(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
        vendorName: order.vendorName,
        reason: reason,
      );

      await Future.delayed(const Duration(milliseconds: 800));
      _processingOrderIds.remove(orderId);
      return true;
    } catch (e) {
      debugPrint('❌ Reject order error: $e');
      _error = 'Failed to reject order: ${e.toString()}';
      _processingOrderIds.remove(orderId);
      notifyListeners();
      return false;
    }
  }

  // ── Mark as Picked Up ─────────────────────────────────────────────────────
  Future<bool> markAsPicked(String orderId, String pickupCode) async {
    try {
      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      if (order.pickupCode != pickupCode) {
        _error = 'Invalid pickup code';
        notifyListeners();
        return false;
      }

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.picked.value,
        'pickedAt': Timestamp.now(),
      });

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderPicked(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Mark picked error: $e');
      _error = 'Failed to update order';
      notifyListeners();
      return false;
    }
  }

  // ── Mark as In Progress ───────────────────────────────────────────────────
  Future<bool> markAsProgress(String orderId) async {
    try {
      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.progress.value,
        'progressAt': Timestamp.now(),
      });

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderInProgress(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Mark progress error: $e');
      _error = 'Failed to update order';
      notifyListeners();
      return false;
    }
  }

  // ── Mark as Ready for Delivery ────────────────────────────────────────────
  Future<bool> markAsReadyForDelivery(String orderId) async {
    try {
      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.readyForDelivery.value,
        'readyForDeliveryAt': Timestamp.now(),
      });

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerReadyForDelivery(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Mark ready for delivery error: $e');
      _error = 'Failed to update order';
      notifyListeners();
      return false;
    }
  }

  // ── Mark as Out for Delivery ──────────────────────────────────────────────
  Future<bool> markAsDelivery(String orderId) async {
    try {
      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.delivery.value,
        'deliveryAt': Timestamp.now(),
      });

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderDelivered(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Mark delivery error: $e');
      _error = 'Failed to update order';
      notifyListeners();
      return false;
    }
  }

  // ── Mark as Completed ─────────────────────────────────────────────────────
  Future<bool> markAsCompleted(String orderId, String enteredDropCode) async {
    try {
      final order = _allOrders.firstWhere(
        (o) => o.orderId == orderId,
        orElse: () => throw Exception('Order not found'),
      );

      if (order.dropCode != enteredDropCode) {
        _error = 'Invalid drop code. Please check with customer.';
        notifyListeners();
        return false;
      }

      if (!order.isPaymentReceived) {
        _error = 'Please mark payment as received first';
        notifyListeners();
        return false;
      }

      await _firebaseService.ordersCollection.doc(orderId).update({
        'status': OrderStatus.completed.value,
        'completedAt': Timestamp.now(),
      });

      // Vendor notification (existing)
      await NotificationService.sendOrderCompletedNotification(
        vendorId: order.vendorId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      // 🔥 Customer notification (naya)
      await NotificationService.notifyCustomerOrderCompleted(
        customerId: order.customerId,
        orderId: order.orderId,
        orderShortId: order.orderId.substring(0, 8).toUpperCase(),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Mark completed error: $e');
      _error = 'Failed to complete order';
      notifyListeners();
      return false;
    }
  }

  // ── Update Payment ────────────────────────────────────────────────────────
  Future<bool> updatePayment({
    required String orderId,
    required PaymentMethod method,
    required PaymentStatus status,
  }) async {
    try {
      await _firebaseService.ordersCollection.doc(orderId).update({
        'paymentMethod': method.value,
        'paymentStatus': status.value,
        'isPaymentReceived': status == PaymentStatus.completed,
      });

      final index = _allOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _allOrders[index] = _allOrders[index].copyWith(
          paymentMethod: method,
          paymentStatus: status,
          isPaymentReceived: status == PaymentStatus.completed,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Update payment error: $e');
      _error = 'Failed to update payment';
      notifyListeners();
      return false;
    }
  }

  // ── Mark Payment Received ─────────────────────────────────────────────────
  Future<bool> markPaymentReceived(String orderId, bool received) async {
    try {
      await _firebaseService.ordersCollection.doc(orderId).update({
        'isPaymentReceived': received,
        'paymentStatus': received
            ? PaymentStatus.completed.value
            : PaymentStatus.pending.value,
      });

      final index = _allOrders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _allOrders[index] = _allOrders[index].copyWith(
          isPaymentReceived: received,
          paymentStatus: received
              ? PaymentStatus.completed
              : PaymentStatus.pending,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Mark payment error: $e');
      _error = 'Failed to update payment status';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    _processingOrderIds.clear();
    _notifiedNewOrders.clear();
    _notifiedOnlinePayments.clear();
    super.dispose();
  }
}
