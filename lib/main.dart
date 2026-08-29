import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'firebase_options.dart';
import 'services/fcm_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/vendor_provider.dart';
import 'providers/order_provider.dart';
import 'providers/service_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/customer_review_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/earnings_provider.dart';

// App config
import 'config/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/utils/app_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  /// Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  /// Initialize FCM
  await FcmService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => CustomerReviewProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        title: 'IronCreeze Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
