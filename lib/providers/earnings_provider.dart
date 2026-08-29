import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/firebase_service.dart' hide debugPrint;
import '../data/models/order_model.dart';

class EarningsProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // ═══════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Selected Month / Year ──────────────────────────────────────
  int _selectedMonth = DateTime.now().month;
  int get selectedMonth => _selectedMonth;

  int _selectedYear = DateTime.now().year;
  int get selectedYear => _selectedYear;

  // ── All Completed Orders ───────────────────────────────────────
  List<OrderModel> _allCompletedOrders = [];
  List<OrderModel> get allCompletedOrders => _allCompletedOrders;

  // ── Monthly Filtered Orders ────────────────────────────────────
  List<OrderModel> _monthlyOrders = [];
  List<OrderModel> get monthlyOrders => _monthlyOrders;

  // ═══════════════════════════════════════════════════════════════
  // ALL-TIME CALCULATIONS (from orders)
  // ═══════════════════════════════════════════════════════════════

  // Total earning vendor ka (subtotal of all completed orders)
  double _totalEarnings = 0.0;
  double get totalEarnings => _totalEarnings;

  // COD se kitna cash vendor ke haath me aaya (total amount — not subtotal)
  double _codCollected = 0.0;
  double get codCollected => _codCollected;

  // Online/Wallet orders ka subtotal — ye wallet me add hoga
  double _walletEarnings = 0.0;
  double get walletEarnings => _walletEarnings;

  // COD orders ka platform fee — vendor ko app ko dena hai
  double _platformFeeDue = 0.0;
  double get platformFeeDue => _platformFeeDue;

  // Total withdrawn (from withdrawals subcollection)
  double _totalWithdrawn = 0.0;
  double get totalWithdrawn => _totalWithdrawn;

  // ── Computed Balances ──────────────────────────────────────────

  // Wallet balance = online/wallet earnings - withdrawn amount
  double get walletBalance => _walletEarnings - _totalWithdrawn;

  // Available to withdraw = wallet balance (only online/wallet money)
  double get availableToWithdraw => walletBalance > 0 ? walletBalance : 0;

  // ═══════════════════════════════════════════════════════════════
  // MONTHLY CALCULATIONS
  // ═══════════════════════════════════════════════════════════════

  double _monthlyEarnings = 0.0;
  double get monthlyEarnings => _monthlyEarnings;

  int _monthlyCompletedOrders = 0;
  int get monthlyCompletedOrders => _monthlyCompletedOrders;

  double _monthlyCodCollected = 0.0;
  double get monthlyCodCollected => _monthlyCodCollected;

  double _monthlyWalletEarnings = 0.0;
  double get monthlyWalletEarnings => _monthlyWalletEarnings;

  double _monthlyPlatformFeeDue = 0.0;
  double get monthlyPlatformFeeDue => _monthlyPlatformFeeDue;

  // ── Recent Transactions (latest 10) ────────────────────────────
  List<OrderModel> get recentTransactions {
    if (_allCompletedOrders.length <= 10) return _allCompletedOrders;
    return _allCompletedOrders.sublist(0, 10);
  }

  // ── Withdrawals ────────────────────────────────────────────────
  List<Map<String, dynamic>> _recentWithdrawals = [];
  List<Map<String, dynamic>> get recentWithdrawals => _recentWithdrawals;

  List<Map<String, dynamic>> _allWithdrawals = [];
  List<Map<String, dynamic>> get allWithdrawals => _allWithdrawals;

  // ═══════════════════════════════════════════════════════════════
  // MONTH NAMES
  // ═══════════════════════════════════════════════════════════════

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get selectedMonthName => monthNames[_selectedMonth - 1];
  String get selectedMonthYear =>
      '${monthNames[_selectedMonth - 1]} $_selectedYear';

  // ═══════════════════════════════════════════════════════════════
  // FETCH ALL EARNINGS DATA
  // ═══════════════════════════════════════════════════════════════

  void resetToCurrentMonth() {
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  Future<void> fetchEarningsData(String vendorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await Future.wait([
        _fetchAllCompletedOrders(vendorId),
        _fetchTotalWithdrawn(vendorId),
        _fetchRecentWithdrawals(vendorId),
      ]);

      // Calculate all-time totals
      _calculateAllTimeTotals();

      // Filter for selected month
      _filterMonthlyOrders();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchEarningsData error: $e');
      _error = 'Failed to fetch earnings data';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH ALL COMPLETED ORDERS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchAllCompletedOrders(String vendorId) async {
    final querySnapshot = await _firebaseService.ordersCollection
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .get();

    _allCompletedOrders = querySnapshot.docs
        .map((doc) => OrderModel.fromFirestore(doc))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // CALCULATE ALL-TIME TOTALS (COD vs Online/Wallet)
  // ═══════════════════════════════════════════════════════════════

  void _calculateAllTimeTotals() {
    _totalEarnings = 0.0;
    _codCollected = 0.0;
    _walletEarnings = 0.0;
    _platformFeeDue = 0.0;

    for (var order in _allCompletedOrders) {
      _totalEarnings += order.subtotal;

      // ✅ FIX: null check — null matlab COD treat karo
      // Kyunki agar online hota to paymentMethod set hoti
      final isCod =
          order.paymentMethod == null ||
          order.paymentMethod == PaymentMethod.cod;

      if (isCod) {
        _codCollected += order.total;
        _platformFeeDue += order.platformFee;
      } else {
        _walletEarnings += order.subtotal;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER MONTHLY ORDERS (local — no extra query)
  // ═══════════════════════════════════════════════════════════════

  void _filterMonthlyOrders() {
    _monthlyOrders = _allCompletedOrders.where((order) {
      // ✅ FIX: completedAt null ho to createdAt use karo
      final dateToCheck = order.completedAt ?? order.createdAt;

      return dateToCheck.month == _selectedMonth &&
          dateToCheck.year == _selectedYear;
    }).toList();

    _monthlyEarnings = 0.0;
    _monthlyCodCollected = 0.0;
    _monthlyWalletEarnings = 0.0;
    _monthlyPlatformFeeDue = 0.0;

    for (var order in _monthlyOrders) {
      _monthlyEarnings += order.subtotal;

      final isCod =
          order.paymentMethod == null ||
          order.paymentMethod == PaymentMethod.cod;

      if (isCod) {
        _monthlyCodCollected += order.total;
        _monthlyPlatformFeeDue += order.platformFee;
      } else {
        _monthlyWalletEarnings += order.subtotal;
      }
    }

    _monthlyCompletedOrders = _monthlyOrders.length;
  }

  // ═══════════════════════════════════════════════════════════════
  // CHANGE MONTH
  // ═══════════════════════════════════════════════════════════════

  void changeMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    _filterMonthlyOrders();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH TOTAL WITHDRAWN
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchTotalWithdrawn(String vendorId) async {
    try {
      final querySnapshot = await _firebaseService
          .vendorDoc(vendorId)
          .collection('withdrawals')
          .where('status', isEqualTo: 'completed')
          .get();

      _totalWithdrawn = 0.0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        _totalWithdrawn += (data['amount'] ?? 0.0).toDouble();
      }
    } catch (e) {
      debugPrint('⚠️ fetchTotalWithdrawn: $e');
      _totalWithdrawn = 0.0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH RECENT WITHDRAWALS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _fetchRecentWithdrawals(String vendorId) async {
    try {
      final querySnapshot = await _firebaseService
          .vendorDoc(vendorId)
          .collection('withdrawals')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _recentWithdrawals = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('⚠️ fetchRecentWithdrawals: $e');
      _recentWithdrawals = [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // FETCH ALL WITHDRAWALS (history screen)
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchAllWithdrawals(String vendorId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final querySnapshot = await _firebaseService
          .vendorDoc(vendorId)
          .collection('withdrawals')
          .orderBy('createdAt', descending: true)
          .get();

      _allWithdrawals = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchAllWithdrawals: $e');
      _allWithdrawals = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR
  // ═══════════════════════════════════════════════════════════════

  void clearData() {
    _totalEarnings = 0.0;
    _codCollected = 0.0;
    _walletEarnings = 0.0;
    _platformFeeDue = 0.0;
    _totalWithdrawn = 0.0;
    _monthlyEarnings = 0.0;
    _monthlyCompletedOrders = 0;
    _monthlyCodCollected = 0.0;
    _monthlyWalletEarnings = 0.0;
    _monthlyPlatformFeeDue = 0.0;
    _allCompletedOrders = [];
    _monthlyOrders = [];
    _recentWithdrawals = [];
    _allWithdrawals = [];
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
    notifyListeners();
  }
}
