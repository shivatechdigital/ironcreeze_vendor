import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String name;
  final String? icon;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.name,
    this.icon,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl = '',
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ServiceModel(
      id: doc.id,
      name: data['name'] ?? '',
      icon: data['icon'],
      imageUrl: data['imageUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (icon != null) 'icon': icon,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  // Get display icon (prefer emoji icon, fallback to first letter)
  String get displayIcon {
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    // Return first letter of name as fallback
    return name.isNotEmpty ? name[0].toUpperCase() : '🏷️';
  }
}

// Vendor's selected service with custom price
class VendorServiceModel {
  final String serviceId;
  final String name;
  final double price;
  final String imageUrl;
  final String? icon;
  final bool isActive;
  final DateTime addedAt;

  VendorServiceModel({
    required this.serviceId,
    required this.name,
    required this.price,
    this.isActive = true,
    this.imageUrl = '',
    this.icon,
    required this.addedAt,
  });

  factory VendorServiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VendorServiceModel(
      serviceId: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      icon: data['icon'],
      isActive: data['isActive'] ?? true,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'isActive': isActive,
      'imageUrl': imageUrl,
      if (icon != null) 'icon': icon,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  VendorServiceModel copyWith({double? price, bool? isActive, String? icon}) {
    return VendorServiceModel(
      serviceId: serviceId,
      name: name,
      price: price ?? this.price,
      imageUrl: imageUrl,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      addedAt: addedAt,
    );
  }

  String get displayIcon {
    if (icon != null && icon!.isNotEmpty) {
      return icon!;
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '🏷️';
  }
}
