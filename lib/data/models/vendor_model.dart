import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/vendor_status.dart';
import '../../core/enums/auth_type.dart';

class VendorModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final AuthType authType;
  final String? profileImage;
  final String shopName;
  final String address;
  final String city;
  final String pinCode;
  final String contactNumber;
  final String? aadharFront;
  final String? aadharBack;
  final VendorStatus status;
  final String? rejectionReason;
  final bool isOnline;
  final double rating;
  final int totalOrders;
  final int completedOrders;
  final double totalEarnings;
  final double totalWithdrawn; // ✅ NEW
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? fcmToken;

  VendorModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.authType,
    this.profileImage,
    required this.shopName,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.contactNumber,
    this.aadharFront,
    this.aadharBack,
    this.status = VendorStatus.pending,
    this.rejectionReason,
    this.isOnline = false,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.totalEarnings = 0.0,
    this.totalWithdrawn = 0.0, // ✅ NEW
    required this.createdAt,
    this.approvedAt,
    this.fcmToken,
    String? profilePicture,
  });

  // ✅ Computed property
  double get availableBalance => totalEarnings - totalWithdrawn;

  factory VendorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VendorModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      authType: AuthType.fromString(data['authType'] ?? 'email'),
      profileImage: data['profileImage'],
      shopName: data['shopName'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      pinCode: data['pinCode'] ?? '',
      contactNumber: data['contactNumber'] ?? '',
      aadharFront: data['aadharFront'],
      aadharBack: data['aadharBack'],
      status: VendorStatus.fromString(data['status'] ?? 'pending'),
      rejectionReason: data['rejectionReason'],
      isOnline: data['isOnline'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalOrders: data['totalOrders'] ?? 0,
      completedOrders: data['completedOrders'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      totalWithdrawn: (data['totalWithdrawn'] ?? 0.0).toDouble(), // ✅ NEW
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'authType': authType.value,
      'profileImage': profileImage,
      'shopName': shopName,
      'address': address,
      'city': city,
      'pinCode': pinCode,
      'contactNumber': contactNumber,
      'aadharFront': aadharFront,
      'aadharBack': aadharBack,
      'status': status.value,
      'rejectionReason': rejectionReason,
      'isOnline': isOnline,
      'rating': rating,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'totalEarnings': totalEarnings,
      'totalWithdrawn': totalWithdrawn, // ✅ NEW
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
    };
  }

  VendorModel copyWith({
    String? name,
    String? email,
    String? phone,
    AuthType? authType,
    String? profileImage,
    String? shopName,
    String? address,
    String? city,
    String? pinCode,
    String? contactNumber,
    String? aadharFront,
    String? aadharBack,
    VendorStatus? status,
    String? rejectionReason,
    bool? isOnline,
    double? rating,
    int? totalOrders,
    int? completedOrders,
    double? totalEarnings,
    double? totalWithdrawn, // ✅ NEW
    DateTime? approvedAt,
    String? fcmToken,
  }) {
    return VendorModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      authType: authType ?? this.authType,
      profileImage: profileImage ?? this.profileImage,
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      contactNumber: contactNumber ?? this.contactNumber,
      aadharFront: aadharFront ?? this.aadharFront,
      aadharBack: aadharBack ?? this.aadharBack,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isOnline: isOnline ?? this.isOnline,
      rating: rating ?? this.rating,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn, // ✅ NEW
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  String toString() {
    return 'VendorModel(uid: $uid, name: $name, status: ${status.value})';
  }
}
