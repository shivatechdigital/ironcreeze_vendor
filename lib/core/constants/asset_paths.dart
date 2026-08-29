class AssetPaths {
  AssetPaths._();

  // Base Paths
  static const String _images = 'assets/images';
  // static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';

  // Images
  static const String logo = '$_images/logo.png';
  static const String logoWhite = '$_images/logo_white.png';
  static const String placeholder = '$_images/placeholder.png';
  static const String userPlaceholder = '$_images/user_placeholder.png';
  static const String emptyOrders = '$_images/empty_orders.png';
  static const String emptyNotifications = '$_images/empty_notifications.png';
  static const String pending = '$_images/pending.png';
  static const String success = '$_images/success.png';
  static const String error = '$_images/error.png';
  static const String noInternet = '$_images/no_internet.png';

  // Onboarding Images
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';

  // Animations (Lottie)
  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/success.json';
  static const String errorAnimation = '$_animations/error.json';
  static const String emptyAnimation = '$_animations/empty.json';
  static const String pendingAnimation = '$_animations/pending.json';
}
