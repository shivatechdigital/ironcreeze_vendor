import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ironcreze_vendor/core/utils/app_navigator.dart';
import 'package:ironcreze_vendor/data/models/order_model.dart';
import 'package:ironcreze_vendor/routes/app_routes.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZE
  // ═══════════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _createNotificationChannels();
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE NOTIFICATION CHANNELS
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
            as AndroidFlutterLocalNotificationsPlugin?;

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          'orders_channel',
          'New Orders',
          description: 'Notifications for new orders',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(
            'notification_sound',
          ),
          enableVibration: true,
          vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
          enableLights: true,
          ledColor: const Color(0xFFFF6B00),
        ),
      );

      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'general_channel',
          'General',
          description: 'General notifications',
          importance: Importance.high,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHOW ORDER NOTIFICATION
  // ═══════════════════════════════════════════════════════════════
  static Future<void> showOrderNotification(RemoteMessage message) async {
    final data = message.data;

    final String orderId = data['orderId'] ?? '';
    final String customerName = data['customerName'] ?? 'Customer';
    final String total = data['total'] ?? '0';
    final String itemCount = data['itemCount'] ?? '0';
    final String itemSummary = data['itemSummary'] ?? '';
    final String orderTime = data['orderTime'] ?? '';
    final shortOrderId = orderId.length > 6
        ? orderId.substring(orderId.length - 6)
        : orderId;

    // 🔥 Consistent id — cancel karne ke liye orderId.hashCode use karo
    final int notificationId = orderId.hashCode.abs();

    final BigTextStyleInformation bigTextStyle = BigTextStyleInformation(
      '👤 <b>$customerName</b>\n'
      '📦 $itemCount items: $itemSummary\n'
      '💰 <b>Total: ₹$total</b>\n'
      '⏰ $orderTime',
      htmlFormatBigText: true,
      contentTitle: '🛒 <b>New Order #${shortOrderId.toUpperCase()}</b>',
      htmlFormatContentTitle: true,
      summaryText: 'IronCreeze Partner',
      htmlFormatSummaryText: true,
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'orders_channel',
          'New Orders',
          channelDescription: 'Notifications for new orders',
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFFFF6B00),
          colorized: true,
          icon: '@drawable/ic_notification',
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: bigTextStyle,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound(
            'notification_sound',
          ),
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          enableLights: true,
          ledColor: const Color(0xFFFF6B00),
          ledOnMs: 500,
          ledOffMs: 500,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          when: DateTime.now().millisecondsSinceEpoch,
          showWhen: true,
          category: AndroidNotificationCategory.message,
          tag: 'order_$orderId',
          // 🔥 tap karte hi notification tray se hat jaayegi
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'accept',
              '✅ Accept',
              showsUserInterface: true,
              // 🔥 action tap pe bhi hat jaayegi
              cancelNotification: true,
            ),
            const AndroidNotificationAction(
              'view',
              '👁️ View',
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'notification_sound.aiff',
      badgeNumber: 1,
      subtitle: 'New Order Received',
      threadIdentifier: 'orders',
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _notificationsPlugin.show(
      notificationId,
      '🛒 New Order Received!',
      '$customerName placed an order worth ₹$total',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHOW SIMPLE NOTIFICATION
  // ═══════════════════════════════════════════════════════════════
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general_channel',
          'General',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFFF6B00),
          icon: '@drawable/ic_notification',
          autoCancel: true,
        );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FOREGROUND TAP HANDLER
  // ═══════════════════════════════════════════════════════════════
  static void _onNotificationResponse(NotificationResponse response) async {
    debugPrint('🔔 Notification tapped — action: ${response.actionId}');

    if (response.payload == null) return;

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.payload!);
    } catch (_) {
      // payload simple orderId string ho sakta hai (showSimpleNotification se)
      data = {'orderId': response.payload};
    }

    final String orderId = data['orderId'] ?? '';

    // 🔥 Manually cancel karo — autoCancel ka backup
    if (orderId.isNotEmpty) {
      await _notificationsPlugin.cancel(
        orderId.hashCode.abs(),
        tag: 'order_$orderId',
      );
    }

    switch (response.actionId) {
      case 'accept':
        if (orderId.isNotEmpty) {
          await _acceptOrderInFirestore(orderId);
        }
        break;

      case 'view':
      default:
        // 🔥 Firestore se OrderModel fetch karo phir navigate karo
        if (orderId.isNotEmpty) {
          await _navigateToOrderDetail(orderId);
        }
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BACKGROUND TAP HANDLER
  // ═══════════════════════════════════════════════════════════════
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(
    NotificationResponse response,
  ) async {
    debugPrint('🔔 Background tap — action: ${response.actionId}');

    if (response.payload == null) return;

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(response.payload!);
    } catch (_) {
      data = {'orderId': response.payload};
    }

    final String orderId = data['orderId'] ?? '';

    // 🔥 Background mein sirf accept handle karo
    // view/default: app foreground mein aa jaayegi, fcm_service handle karega
    if (response.actionId == 'accept' && orderId.isNotEmpty) {
      await _acceptOrderInFirestore(orderId);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Firestore mein order status 'accepted' update karo
  static Future<void> _acceptOrderInFirestore(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'accepted', 'acceptedAt': FieldValue.serverTimestamp()},
      );
      debugPrint('✅ Order accepted: $orderId');
    } catch (e) {
      debugPrint('❌ Firestore accept failed: $e');
    }
  }

  /// Firestore se OrderModel fetch karo aur Order Detail screen pe navigate karo
  static Future<void> _navigateToOrderDetail(String orderId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!doc.exists) {
        debugPrint('❌ Order not found: $orderId');
        return;
      }

      final order = OrderModel.fromFirestore(doc);

      AppNavigator.navigatorKey.currentState?.pushNamed(
        AppRoutes.orderDetails,
        arguments: order, // 🔥 OrderModel pass karo — String nahi
      );
    } catch (e) {
      debugPrint('❌ Navigation failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CANCEL
  // ═══════════════════════════════════════════════════════════════
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
