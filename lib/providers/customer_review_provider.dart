// lib/providers/customer_review_provider.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/customer_review_model.dart';
import '../data/models/customer_rating_summary.dart';

class CustomerReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  // ✅ Cache for customer ratings (customerId -> summary)
  final Map<String, CustomerRatingSummary> _ratingsCache = {};

  // ✅ Track loading state for individual customers
  final Set<String> _loadingCustomerIds = {};

  // ─── Get cached rating (returns null if not loaded) ────────────────────────
  CustomerRatingSummary? getCachedRating(String customerId) {
    return _ratingsCache[customerId];
  }

  // ─── Check if rating is being loaded ───────────────────────────────────────
  bool isLoadingRating(String customerId) {
    return _loadingCustomerIds.contains(customerId);
  }

  // ─── Fetch rating summary for a customer ───────────────────────────────────
  Future<CustomerRatingSummary> fetchCustomerRating(String customerId) async {
    // Return cached if available
    if (_ratingsCache.containsKey(customerId)) {
      return _ratingsCache[customerId]!;
    }

    // Prevent duplicate fetches
    if (_loadingCustomerIds.contains(customerId)) {
      await Future.delayed(const Duration(milliseconds: 100));
      return _ratingsCache[customerId] ??
          CustomerRatingSummary.empty(customerId);
    }

    _loadingCustomerIds.add(customerId);
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('customer_reviews')
          .where('customerId', isEqualTo: customerId)
          .get();

      final reviews = snapshot.docs;

      CustomerRatingSummary summary;

      if (reviews.isEmpty) {
        summary = CustomerRatingSummary.empty(customerId);
      } else {
        final totalRating = reviews.fold<double>(
          0.0,
          (sum, doc) => sum + ((doc.data()['rating'] ?? 0) as num).toDouble(),
        );
        summary = CustomerRatingSummary(
          customerId: customerId,
          averageRating: totalRating / reviews.length,
          totalReviews: reviews.length,
        );
      }

      _ratingsCache[customerId] = summary;
      _loadingCustomerIds.remove(customerId);
      notifyListeners();

      return summary;
    } catch (e) {
      debugPrint('❌ Fetch customer rating error: $e');
      _loadingCustomerIds.remove(customerId);
      final emptySummary = CustomerRatingSummary.empty(customerId);
      _ratingsCache[customerId] = emptySummary;
      notifyListeners();
      return emptySummary;
    }
  }

  // ─── Fetch ratings for multiple customers at once (batch) ──────────────────
  Future<void> fetchRatingsForCustomers(List<String> customerIds) async {
    // Filter out already cached ones
    final idsToFetch = customerIds
        .where(
          (id) =>
              !_ratingsCache.containsKey(id) &&
              !_loadingCustomerIds.contains(id),
        )
        .toSet()
        .toList();

    if (idsToFetch.isEmpty) return;

    for (final id in idsToFetch) {
      _loadingCustomerIds.add(id);
    }
    notifyListeners();

    try {
      // Firestore 'whereIn' limit is 10, so batch if needed
      for (var i = 0; i < idsToFetch.length; i += 10) {
        final batch = idsToFetch.skip(i).take(10).toList();

        final snapshot = await _firestore
            .collection('customer_reviews')
            .where('customerId', whereIn: batch)
            .get();

        // Group reviews by customerId
        final reviewsByCustomer = <String, List<double>>{};
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final custId = data['customerId'] as String;
          final rating = ((data['rating'] ?? 0) as num).toDouble();
          reviewsByCustomer.putIfAbsent(custId, () => []).add(rating);
        }

        // Create summaries
        for (final customerId in batch) {
          final ratings = reviewsByCustomer[customerId];
          if (ratings == null || ratings.isEmpty) {
            _ratingsCache[customerId] = CustomerRatingSummary.empty(customerId);
          } else {
            final avg = ratings.reduce((a, b) => a + b) / ratings.length;
            _ratingsCache[customerId] = CustomerRatingSummary(
              customerId: customerId,
              averageRating: avg,
              totalReviews: ratings.length,
            );
          }
          _loadingCustomerIds.remove(customerId);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Batch fetch ratings error: $e');
      for (final id in idsToFetch) {
        _loadingCustomerIds.remove(id);
        _ratingsCache.putIfAbsent(id, () => CustomerRatingSummary.empty(id));
      }
      notifyListeners();
    }
  }

  // ─── Clear cache (call on logout) ──────────────────────────────────────────
  void clearCache() {
    _ratingsCache.clear();
    _loadingCustomerIds.clear();
    notifyListeners();
  }

  // ─── Submit a new review ───────────────────────────────────────────────────
  Future<bool> submitReview({
    required String orderId,
    required String customerId,
    required String customerName,
    required String vendorId,
    required double rating,
    String? review,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      // Check if review already exists for this order
      final existing = await _firestore
          .collection('customer_reviews')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        _isSubmitting = false;
        _error = 'Review already submitted for this order';
        notifyListeners();
        return false;
      }

      final docRef = _firestore.collection('customer_reviews').doc();

      final reviewModel = CustomerReviewModel(
        id: docRef.id,
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        vendorId: vendorId,
        rating: rating,
        review: review?.trim().isEmpty ?? true ? null : review?.trim(),
        createdAt: DateTime.now(),
      );

      await docRef.set(reviewModel.toFirestore());

      // ✅ Update cache immediately
      final currentSummary = _ratingsCache[customerId];
      if (currentSummary != null) {
        final newTotal = currentSummary.totalReviews + 1;
        final newAvg =
            ((currentSummary.averageRating * currentSummary.totalReviews) +
                rating) /
            newTotal;
        _ratingsCache[customerId] = CustomerRatingSummary(
          customerId: customerId,
          averageRating: newAvg,
          totalReviews: newTotal,
        );
      } else {
        _ratingsCache[customerId] = CustomerRatingSummary(
          customerId: customerId,
          averageRating: rating,
          totalReviews: 1,
        );
      }

      debugPrint('✅ Review submitted: $rating⭐ for customer $customerId');

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Submit review error: $e');
      _error = 'Failed to submit review. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Check if review already exists for an order ───────────────────────────
  Future<bool> hasReviewForOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection('customer_reviews')
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ─── Get all reviews for a customer ────────────────────────────────────────
  Future<List<CustomerReviewModel>> getReviewsForCustomer(
    String customerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('customer_reviews')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CustomerReviewModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Get reviews error: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
