// lib/core/utils/app_navigator.dart

import 'package:flutter/material.dart';

class AppNavigator {
  AppNavigator._();

  /// Global navigator key - survives widget disposal
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Get current navigator state
  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Get current context from navigator
  static BuildContext? get context => navigatorKey.currentContext;

  /// Show dialog using global navigator (survives widget disposal)
  static Future<T?> showGlobalDialog<T>({
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    final ctx = context;
    if (ctx == null) {
      debugPrint('AppNavigator: No context available for dialog');
      return null;
    }

    return showDialog<T>(
      context: ctx,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  /// Show bottom sheet using global navigator
  static Future<T?> showGlobalBottomSheet<T>({
    required WidgetBuilder builder,
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    final ctx = context;
    if (ctx == null) return null;

    return showModalBottomSheet<T>(
      context: ctx,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: builder,
    );
  }

  /// Navigate to named route
  static Future<T?>? pushNamed<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Replace current route
  static Future<T?>? pushReplacementNamed<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator?.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }

  /// Clear stack and push
  static Future<T?>? pushNamedAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
  }) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop current route
  static void pop<T>([T? result]) {
    navigator?.pop(result);
  }
}
