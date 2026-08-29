import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  late StreamSubscription<ConnectivityResult> _subscription;

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Check initial connectivity
    final result = await Connectivity().checkConnectivity();
    _updateConnectionStatus(result as ConnectivityResult);

    // Listen for changes
    _subscription =
        Connectivity().onConnectivityChanged.listen(
              _updateConnectionStatus
                  as void Function(List<ConnectivityResult> event)?,
            )
            as StreamSubscription<ConnectivityResult>;
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();
  }

  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    notifyListeners();
    return _isConnected;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
