import 'dart:math';

class CodeGenerator {
  CodeGenerator._();

  static final Random _random = Random();

  // Generate Pickup Code (4 digits)
  static String generatePickupCode() {
    return _generateNumericCode(4);
  }

  // Generate Drop Code (4 digits)
  static String generateDropCode() {
    return _generateNumericCode(4);
  }

  // Generate Order ID
  static String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = _generateNumericCode(4);
    return 'ORD$timestamp$randomPart';
  }

  // Generate Vendor ID
  static String generateVendorId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = _generateAlphaNumericCode(4);
    return 'VEN$timestamp$randomPart';
  }

  // Generate Numeric Code
  static String _generateNumericCode(int length) {
    String code = '';
    for (int i = 0; i < length; i++) {
      code += _random.nextInt(10).toString();
    }
    return code;
  }

  // Generate Alpha Numeric Code
  static String _generateAlphaNumericCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < length; i++) {
      code += chars[_random.nextInt(chars.length)];
    }
    return code;
  }
}
