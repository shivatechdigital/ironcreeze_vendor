import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase Instances
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  FirebaseStorage get storage => FirebaseStorage.instance;
  FirebaseMessaging get messaging => FirebaseMessaging.instance;

  // Current User
  User? get currentUser => auth.currentUser;
  String? get currentUserId => auth.currentUser?.uid;
  bool get isLoggedIn => auth.currentUser != null;

  // Platform Check
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isIOS => !kIsWeb && Platform.isIOS;

  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM
    await _initializeFCM();

    debugPrint('✅ Firebase initialized successfully');
  }

  // Initialize FCM
  static Future<void> _initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📱 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM Token
        String? token = await messaging.getToken();
        debugPrint('🔑 FCM Token: $token');

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token refreshed');
          // TODO: Update token in Firestore
        });
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground message: ${message.notification?.title}');
        // TODO: Show local notification
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification tap (app in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 Notification tapped');
        // TODO: Navigate to specific screen
      });
    } catch (e) {
      debugPrint('⚠️ FCM initialization error: $e');
    }
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('📩 Background message: ${message.messageId}');
  }

  // ═══════════════════════════════════════════════════════════════
  // COLLECTION REFERENCES
  // ═══════════════════════════════════════════════════════════════

  CollectionReference get vendorsCollection => firestore.collection('vendors');
  CollectionReference get ordersCollection => firestore.collection('orders');
  CollectionReference get servicesCollection =>
      firestore.collection('products');
  CollectionReference get adminCollection => firestore.collection('admin');
  CollectionReference get notificationsCollection =>
      firestore.collection('notifications');

  // ═══════════════════════════════════════════════════════════════
  // DOCUMENT REFERENCES
  // ═══════════════════════════════════════════════════════════════

  DocumentReference vendorDoc(String vendorId) =>
      vendorsCollection.doc(vendorId);

  // ═══════════════════════════════════════════════════════════════
  // SUBCOLLECTION REFERENCES
  // ═══════════════════════════════════════════════════════════════

  CollectionReference vendorServicesCollection(String vendorId) =>
      vendorDoc(vendorId).collection('services');

  // ═══════════════════════════════════════════════════════════════
  // STORAGE REFERENCES
  // ═══════════════════════════════════════════════════════════════

  Reference profileImageRef(String userId, String fileName) =>
      storage.ref().child('vendors/profiles/$userId/$fileName');

  Reference documentRef(String userId, String fileName) =>
      storage.ref().child('vendors/documents/$userId/$fileName');
}

// Required for background message handler
void debugPrint(String message) {
  print(message);
}
