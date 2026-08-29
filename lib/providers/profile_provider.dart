import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/firebase_service.dart' hide debugPrint;

class ProfileProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Rating (from vendor_reviews collection) ────────────────────
  double _rating = 0.0;
  double get rating => _rating;

  int _totalReviews = 0;
  int get totalReviews => _totalReviews;

  // ── Current Month Stats (from orders collection) ───────────────
  int _monthlyCompletedOrders = 0;
  int get monthlyCompletedOrders => _monthlyCompletedOrders;

  double _monthlyEarnings = 0.0;
  double get monthlyEarnings => _monthlyEarnings;

  // ── Current Month Info ─────────────────────────────────────────
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;

  int _totalCompletedOrders = 0;
  int get totalCompletedOrders => _totalCompletedOrders;

  static const List<String> _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get currentMonthName => _monthNames[_currentMonth - 1];

  // ═══════════════════════════════════════════════════════════════
  // FETCH ALL PROFILE STATS
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchProfileStats(String vendorId) async {
    try {
      _isLoading = true;
      _error = null;
      _currentMonth = DateTime.now().month;
      _currentYear = DateTime.now().year;
      notifyListeners();

      // Fetch both simultaneously
      await Future.wait([
        _fetchRating(vendorId),
        _fetchMonthlyStats(vendorId),
        _fetchTotalOrders(vendorId),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchProfileStats error: $e');
      _error = 'Failed to fetch profile stats';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchTotalOrders(String vendorId) async {
    try {
      final querySnapshot = await _firebaseService.ordersCollection
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'completed')
          .get();

      _totalCompletedOrders = querySnapshot.docs.length;
    } catch (e) {
      debugPrint('⚠️ fetchTotalOrders error: $e');
      _totalCompletedOrders = 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH RATING from vendor_reviews collection
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchRating(String vendorId) async {
    try {
      final querySnapshot = await _firebaseService.firestore
          .collection('vendor_reviews')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _rating = 0.0;
        _totalReviews = 0;
        return;
      }

      _totalReviews = querySnapshot.docs.length;

      double totalRating = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0.0).toDouble();
      }

      _rating = totalRating / _totalReviews;
    } catch (e) {
      debugPrint('⚠️ fetchRating error: $e');
      _rating = 0.0;
      _totalReviews = 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH MONTHLY STATS from orders collection
  // Current month completed orders + earnings
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchMonthlyStats(String vendorId) async {
    try {
      // Current month start & end
      final startOfMonth = DateTime(_currentYear, _currentMonth, 1);
      final endOfMonth = DateTime(
        _currentYear,
        _currentMonth + 1,
        0,
        23,
        59,
        59,
        999,
      );

      // Query completed orders for current month
      // Using createdAt as fallback (completedAt might be null)
      final querySnapshot = await _firebaseService.ordersCollection
          .where('vendorId', isEqualTo: vendorId)
          .where('status', isEqualTo: 'completed')
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'createdAt',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
          .get();

      _monthlyCompletedOrders = querySnapshot.docs.length;

      double totalEarnings = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // COD or null paymentMethod → vendor already has cash
        // Online/Wallet → subtotal is vendor's earnings
        // Either way, subtotal = vendor's earning per order
        totalEarnings += (data['subtotal'] ?? 0.0).toDouble();
      }

      _monthlyEarnings = totalEarnings;
    } catch (e) {
      debugPrint('⚠️ fetchMonthlyStats error: $e');
      _monthlyCompletedOrders = 0;
      _monthlyEarnings = 0.0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  void clearData() {
    _rating = 0.0;
    _totalReviews = 0;
    _totalCompletedOrders = 0;
    _monthlyCompletedOrders = 0;
    _monthlyEarnings = 0.0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
