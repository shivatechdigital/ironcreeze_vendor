// lib/data/models/customer_rating_summary.dart

class CustomerRatingSummary {
  final String customerId;
  final double averageRating;
  final int totalReviews;

  CustomerRatingSummary({
    required this.customerId,
    required this.averageRating,
    required this.totalReviews,
  });

  /// No reviews yet
  factory CustomerRatingSummary.empty(String customerId) {
    return CustomerRatingSummary(
      customerId: customerId,
      averageRating: 0.0,
      totalReviews: 0,
    );
  }

  bool get hasRatings => totalReviews > 0;

  String get displayRating => averageRating.toStringAsFixed(1);
}
