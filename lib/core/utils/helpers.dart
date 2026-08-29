import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';

class Helpers {
  Helpers._();

  // Show Toast
  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppColors.error : AppColors.grey800,
      textColor: AppColors.white,
      fontSize: 14.0,
    );
  }

  // Show Success Toast
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
      fontSize: 14.0,
    );
  }

  // Show Error Toast
  static void showErrorToast(String message) {
    showToast(message, isError: true);
  }

  // Show Snackbar
  static void showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.grey800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Hide Keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // Get Initials from Name
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return names[0][0].toUpperCase();
  }

  // Format Phone Number
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  // Format Currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Mask Email
  static String maskEmail(String email) {
    if (email.isEmpty) return '';

    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '$username***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }

  // Mask Phone
  static String maskPhone(String phone) {
    if (phone.length < 10) return phone;

    final last4 = phone.substring(phone.length - 4);
    return '******$last4';
  }

  // Check if String is Numeric
  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) return false;
    return double.tryParse(value) != null;
  }
}
