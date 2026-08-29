class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'IronCreeze Partner';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Firebase Collections
  static const String vendorsCollection = 'vendors';
  static const String ordersCollection = 'orders';
  static const String servicesCollection = 'services';
  static const String adminCollection = 'admin';
  static const String notificationsCollection = 'notifications';

  // Storage Paths
  static const String vendorProfileImages = 'vendors/profiles';
  static const String vendorDocuments = 'vendors/documents';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // Pagination
  static const int ordersPerPage = 20;

  // Admin Contact (Default - can be fetched from Firebase)
  static const String adminPhone = '+919876543210';
  static const String adminEmail = 'admin@ironcreze.com';

  // Platform Fee
  static const double platformFeePercentage = 10.0;

  // OTP
  static const int otpLength = 6;
  static const int otpResendTime = 60; // seconds

  // Image
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int imageQuality = 70;

  // Validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int pinCodeLength = 6;
  static const int phoneLength = 10;
}
