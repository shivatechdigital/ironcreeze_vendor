// lib/data/models/customer_review_model.dart
// ✅ Firestore collection: 'customer_reviews'
// One document per review — customerId + vendorId + orderId stored for lookup

import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerReviewModel {
  final String id; // Firestore doc id
  final String orderId; // Which order this review is for
  final String customerId; // Who is being reviewed (the customer)
  final String customerName;
  final String vendorId; // Who gave the review (the vendor)
  final double rating; // 1.0 – 5.0
  final String? review; // Optional text review
  final DateTime createdAt;

  CustomerReviewModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.vendorId,
    required this.rating,
    this.review,
    required this.createdAt,
  });

  factory CustomerReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CustomerReviewModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      vendorId: data['vendorId'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      review: data['review'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'vendorId': vendorId,
      'rating': rating,
      'review': review,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
