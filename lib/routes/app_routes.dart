import 'package:flutter/material.dart';
import '../views/splash/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/signup_screen.dart';
import '../views/auth/otp_verification_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/registration/vendor_details_screen.dart';
import '../views/registration/document_upload_screen.dart';
import '../views/registration/pending_approval_screen.dart';
import '../views/home/main_navigation_screen.dart';
import '../views/orders/order_details_screen.dart';
import '../views/profile/edit_profile_screen.dart';
import '../views/profile/my_services_screen.dart';
import '../views/notifications/notifications_screen.dart';
import '../data/models/order_model.dart';
import '../views/earnings/earnings_screen.dart';
import '../views/earnings/withdrawal_history_screen.dart';

class AppRoutes {
  AppRoutes._();

  // Route Names
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String vendorDetails = '/vendor-details';
  static const String documentUpload = '/document-upload';
  static const String pendingApproval = '/pending-approval';
  static const String mainNavigation = '/main';
  static const String orderDetails = '/order-details';
  static const String editProfile = '/edit-profile';
  static const String myServices = '/my-services';
  static const String notifications = '/notifications';
  static const String earnings = '/earnings';
  static const String withdrawalHistory = '/withdrawal-history';

  // Route Generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case signup:
        return _buildRoute(const SignupScreen(), settings);

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(
            verificationId: args?['verificationId'] ?? '',
            phoneNumber: args?['phoneNumber'] ?? '',
          ),
          settings,
        );

      case forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      case vendorDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          VendorProfileScreen(
            email: args?['email'],
            phone: args?['phone'],
            authType: args?['authType'],
          ),
          settings,
        );

      case documentUpload:
        return _buildRoute(const DocumentUploadScreen(), settings);

      case pendingApproval:
        return _buildRoute(const PendingApprovalScreen(), settings);

      case mainNavigation:
        return _buildRoute(const MainNavigationScreen(), settings);

      case orderDetails:
        final order = settings.arguments as OrderModel;
        return _buildRoute(OrderDetailsScreen(order: order), settings);

      case editProfile:
        return _buildRoute(const EditProfileScreen(), settings);

      case myServices:
        return _buildRoute(const MyServicesScreen(), settings);

      case notifications:
        return _buildRoute(const NotificationsScreen(), settings);

      case earnings:
        return _buildRoute(const EarningsScreen(), settings);

      case withdrawalHistory:
        return _buildRoute(const WithdrawalHistoryScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  // Build Route with Animation
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Navigation Helpers
  static void navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndReplace(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateAndClearStack(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
