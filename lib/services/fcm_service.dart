import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ironcreze_vendor/core/utils/app_navigator.dart';
import 'package:ironcreze_vendor/data/models/order_model.dart';
import 'package:ironcreze_vendor/routes/app_routes.dart';
import 'local_notification_service.dart';

// 🔥 Background Handler - Must be top-level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 Background message received: ${message.messageId}');
  await Firebase.initializeApp();
  await LocalNotificationService.initialize();
  await LocalNotificationService.showOrderNotification(message);
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  // ═══════════════════════════════════════════════════════════════
  // INITIALIZE FCM
  // ═══════════════════════════════════════════════════════════════
  static Future<void> initialize() async {
    debugPrint('🔔 ====== FCM INITIALIZATION STARTED ======');

    // 1️⃣ Initialize Local Notifications
    await LocalNotificationService.initialize();

    // 2️⃣ Request Permission
    await _requestPermission();

    // 3️⃣ Get & Save Token
    await _getAndSaveToken();

    // 4️⃣ Setup Message Handlers
    _setupMessageHandlers();

    debugPrint('🔔 ====== FCM INITIALIZATION COMPLETED ======');
  }

  // ═══════════════════════════════════════════════════════════════
  // REQUEST PERMISSION
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    debugPrint('🔔 Permission status: ${settings.authorizationStatus}');
  }

  // ═══════════════════════════════════════════════════════════════
  // GET & SAVE TOKEN
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('🔔 FCM Token: $_fcmToken');

      if (_fcmToken != null) {
        await _saveTokenToFirestore(_fcmToken!);
      }

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('🔔 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        await _saveTokenToFirestore(newToken);
      });
    } catch (e) {
      debugPrint('❌ FCM Token error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE TOKEN TO FIRESTORE
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ No user logged in, skipping token save');
      return;
    }

    try {
      await _firestore.collection('vendors').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': 'android',
      }, SetOptions(merge: true));
      debugPrint('✅ FCM Token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MESSAGE HANDLERS
  // ═══════════════════════════════════════════════════════════════
  static void _setupMessageHandlers() {
    // 📱 Foreground Messages — local notification show karo
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message: ${message.data}');
      LocalNotificationService.showOrderNotification(message);
    });

    // 📱 App background mein thi, notification tap se khuli
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 App opened from notification: ${message.data}');
      final orderId = message.data['orderId'];
      if (orderId != null && orderId.isNotEmpty) {
        _navigateToOrderDetail(orderId);
      }
    });

    // 📱 App terminated thi, notification tap se launch hui
    _checkInitialMessage();
  }

  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('📩 Initial message: ${initialMessage.data}');
      final orderId = initialMessage.data['orderId'];
      if (orderId != null && orderId.isNotEmpty) {
        // 🔥 App abhi launch ho rahi hai — thoda wait karo
        await Future.delayed(const Duration(seconds: 1));
        _navigateToOrderDetail(orderId);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATE TO ORDER DETAIL
  // 🔥 orderId se Firestore fetch karo → OrderModel banao → navigate
  // ═══════════════════════════════════════════════════════════════
  static Future<void> _navigateToOrderDetail(String orderId) async {
    if (orderId.isEmpty) return;

    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();

      if (!doc.exists) {
        debugPrint('❌ Order not found: $orderId');
        return;
      }

      final order = OrderModel.fromFirestore(doc);

      AppNavigator.navigatorKey.currentState?.pushNamed(
        AppRoutes.orderDetails,
        arguments: order, // 🔥 OrderModel pass karo, String nahi
      );
    } catch (e) {
      debugPrint('❌ Navigate to order detail failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE TOKEN (ON LOGOUT)
  // ═══════════════════════════════════════════════════════════════
  static Future<void> deleteToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('vendors').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        await _messaging.deleteToken();
        _fcmToken = null;
        debugPrint('✅ FCM Token deleted');
      } catch (e) {
        debugPrint('❌ Failed to delete FCM token: $e');
      }
    }
  }
}
