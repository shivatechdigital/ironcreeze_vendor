class Validators {
  Validators._();

  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Confirm Password Validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Phone Validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^[6-9]\d{9}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // Name Validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  // Shop Name Validation
  static String? validateShopName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shop name is required';
    }

    if (value.length < 2) {
      return 'Shop name must be at least 2 characters';
    }

    if (value.length > 100) {
      return 'Shop name must be less than 100 characters';
    }

    return null;
  }

  // Address Validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }

    if (value.length < 10) {
      return 'Please enter complete address';
    }

    return null;
  }

  // City Validation
  static String? validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'City is required';
    }

    if (value.length < 2) {
      return 'Please enter a valid city name';
    }

    return null;
  }

  // Pin Code Validation
  static String? validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pin code is required';
    }

    final pinRegex = RegExp(r'^\d{6}$');

    if (!pinRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit pin code';
    }

    return null;
  }

  // OTP Validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }

    if (value.length != 6) {
      return 'Please enter 6-digit OTP';
    }

    return null;
  }

  // Required Field Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Price Validation
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null || price <= 0) {
      return 'Please enter a valid price';
    }

    return null;
  }
}
