import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/order_status.dart';

// ─── Payment Method Enum ──────────────────────────────────────────────────────
enum PaymentMethod {
  cod,
  online,
  wallet;

  String get value {
    switch (this) {
      case PaymentMethod.cod:
        return 'cod';
      case PaymentMethod.online:
        return 'online';
      case PaymentMethod.wallet:
        return 'wallet';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.cod:
        return 'Cash on Delivery';
      case PaymentMethod.online:
        return 'Online (UPI/Card)';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }

  static PaymentMethod? fromString(String? value) {
    switch (value) {
      case 'cod':
        return PaymentMethod.cod;
      case 'online':
        return PaymentMethod.online;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return null;
    }
  }
}

// ─── Payment Status Enum ──────────────────────────────────────────────────────
enum PaymentStatus {
  pending,
  completed,
  failed,
  refunded;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.completed:
        return 'completed';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  static PaymentStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  bool get isPending => this == PaymentStatus.pending;
  bool get isCompleted => this == PaymentStatus.completed;
}

// ─── Order Item Model ─────────────────────────────────────────────────────────
class OrderItemModel {
  final String serviceId;
  final String name;
  final double price;
  final int quantity;

  OrderItemModel({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      serviceId: map['serviceId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  // ✅ Computed getter — NOT a constructor param
  double get totalPrice => price * quantity;
}

// ─── Order Model ──────────────────────────────────────────────────────────────
class OrderModel {
  final String orderId;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerCity;
  final String customerPinCode;
  final List<OrderItemModel> items;
  final double subtotal;
  final double platformFee;
  final double total;
  final DateTime pickupDate;
  final DateTime? deliveryDate;
  final String pickupCode;
  final String dropCode;
  final OrderStatus status;
  final bool isPaymentReceived;
  final PaymentMethod? paymentMethod;
  final PaymentStatus paymentStatus;

  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? pickedAt;
  final DateTime? progressAt;
  final DateTime? readyForDeliveryAt;
  final DateTime? deliveryAt;
  final DateTime? completedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  OrderModel({
    required this.orderId,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.customerCity,
    required this.customerPinCode,
    required this.items,
    required this.subtotal,
    required this.platformFee,
    required this.total,
    required this.pickupDate,
    this.deliveryDate,
    required this.pickupCode,
    required this.dropCode,
    this.status = OrderStatus.requested,
    this.isPaymentReceived = false,
    this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.pickedAt,
    this.progressAt,
    this.readyForDeliveryAt,
    this.deliveryAt,
    this.completedAt,
    this.rejectedAt,
    this.rejectionReason,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      orderId: doc.id,
      vendorId: data['vendorId'] ?? '',
      vendorName: data['vendorName'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerAddress: data['customerAddress'] ?? '',
      customerCity: data['customerCity'] ?? '',
      customerPinCode: data['customerPinCode'] ?? '',
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromMap(item))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      platformFee: (data['platformFee'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      pickupDate:
          (data['pickupDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryDate: (data['deliveryDate'] as Timestamp?)?.toDate(),
      pickupCode: data['pickupCode'] ?? '',
      dropCode: data['dropCode'] ?? '',
      status: OrderStatus.fromString(data['status'] ?? 'requested'),
      isPaymentReceived: data['isPaymentReceived'] ?? false,
      paymentMethod: PaymentMethod.fromString(data['paymentMethod']),
      paymentStatus: PaymentStatus.fromString(data['paymentStatus']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      pickedAt: (data['pickedAt'] as Timestamp?)?.toDate(),
      progressAt: (data['progressAt'] as Timestamp?)?.toDate(),
      readyForDeliveryAt: (data['readyForDeliveryAt'] as Timestamp?)?.toDate(),
      deliveryAt: (data['deliveryAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerCity': customerCity,
      'customerPinCode': customerPinCode,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'platformFee': platformFee,
      'total': total,
      'pickupDate': Timestamp.fromDate(pickupDate),
      'deliveryDate': deliveryDate != null
          ? Timestamp.fromDate(deliveryDate!)
          : null,
      'pickupCode': pickupCode,
      'dropCode': dropCode,
      'status': status.value,
      'isPaymentReceived': isPaymentReceived,
      'paymentMethod': paymentMethod?.value,
      'paymentStatus': paymentStatus.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'pickedAt': pickedAt != null ? Timestamp.fromDate(pickedAt!) : null,
      'progressAt': progressAt != null ? Timestamp.fromDate(progressAt!) : null,
      'readyForDeliveryAt': readyForDeliveryAt != null
          ? Timestamp.fromDate(readyForDeliveryAt!)
          : null,
      'deliveryAt': deliveryAt != null ? Timestamp.fromDate(deliveryAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // ✅ copyWith now includes items, subtotal, platformFee, total
  OrderModel copyWith({
    List<OrderItemModel>? items,
    String? vendorName,
    double? subtotal,
    double? platformFee,
    double? total,
    OrderStatus? status,
    bool? isPaymentReceived,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? acceptedAt,
    DateTime? pickedAt,
    DateTime? progressAt,
    DateTime? readyForDeliveryAt,
    DateTime? deliveryAt,
    DateTime? completedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
  }) {
    return OrderModel(
      orderId: orderId,
      vendorId: vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      customerCity: customerCity,
      customerPinCode: customerPinCode,
      items: items ?? this.items, // ✅ added
      subtotal: subtotal ?? this.subtotal, // ✅ added
      platformFee: platformFee ?? this.platformFee, // ✅ added
      total: total ?? this.total, // ✅ added
      pickupDate: pickupDate,
      deliveryDate: deliveryDate,
      pickupCode: pickupCode,
      dropCode: dropCode,
      status: status ?? this.status,
      isPaymentReceived: isPaymentReceived ?? this.isPaymentReceived,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedAt: pickedAt ?? this.pickedAt,
      progressAt: progressAt ?? this.progressAt,
      readyForDeliveryAt: readyForDeliveryAt ?? this.readyForDeliveryAt,
      deliveryAt: deliveryAt ?? this.deliveryAt,
      completedAt: completedAt ?? this.completedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
