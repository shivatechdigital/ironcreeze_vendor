import 'package:flutter/material.dart';
import '../data/models/service_model.dart';
import '../data/services/firebase_service.dart' hide debugPrint;

class ServiceProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<ServiceModel> _adminServices = [];
  List<ServiceModel> get adminServices => _adminServices;

  List<VendorServiceModel> _vendorServices = [];
  List<VendorServiceModel> get vendorServices => _vendorServices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Fetch admin-defined services
  Future<void> fetchAdminServices() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firebaseService.servicesCollection
          .where('isActive', isEqualTo: true)
          .get();

      _adminServices = snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();

      // Sort in memory instead of Firestore
      _adminServices.sort((a, b) => a.name.compareTo(b.name));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch admin services error: $e');
      _error = 'Failed to fetch services';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch vendor's selected services
  Future<void> fetchVendorServices(String vendorId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firebaseService
          .vendorServicesCollection(vendorId)
          .get();

      _vendorServices = snapshot.docs
          .map((doc) => VendorServiceModel.fromFirestore(doc))
          .toList();

      // Sort in memory
      _vendorServices.sort((a, b) => a.name.compareTo(b.name));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch vendor services error: $e');
      _error = 'Failed to fetch your services';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add service to vendor
  Future<bool> addService({
    required String vendorId,
    required ServiceModel service,
    required double price,
  }) async {
    try {
      final vendorService = VendorServiceModel(
        serviceId: service.id,
        name: service.name,
        price: price,
        imageUrl: service.imageUrl,
        icon: service.icon,
        isActive: true,
        addedAt: DateTime.now(),
      );

      await _firebaseService
          .vendorServicesCollection(vendorId)
          .doc(service.id)
          .set(vendorService.toFirestore());

      _vendorServices.add(vendorService);
      _vendorServices.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Add service error: $e');
      _error = 'Failed to add service';
      notifyListeners();
      return false;
    }
  }

  // Update service price
  Future<bool> updateServicePrice({
    required String vendorId,
    required String serviceId,
    required double newPrice,
  }) async {
    try {
      await _firebaseService
          .vendorServicesCollection(vendorId)
          .doc(serviceId)
          .update({'price': newPrice});

      final index = _vendorServices.indexWhere((s) => s.serviceId == serviceId);
      if (index != -1) {
        _vendorServices[index] = _vendorServices[index].copyWith(
          price: newPrice,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Update service price error: $e');
      _error = 'Failed to update price';
      notifyListeners();
      return false;
    }
  }

  // Toggle service active status
  Future<bool> toggleServiceStatus({
    required String vendorId,
    required String serviceId,
    required bool isActive,
  }) async {
    try {
      await _firebaseService
          .vendorServicesCollection(vendorId)
          .doc(serviceId)
          .update({'isActive': isActive});

      final index = _vendorServices.indexWhere((s) => s.serviceId == serviceId);
      if (index != -1) {
        _vendorServices[index] = _vendorServices[index].copyWith(
          isActive: isActive,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Toggle service status error: $e');
      _error = 'Failed to update service';
      notifyListeners();
      return false;
    }
  }

  // Remove service
  Future<bool> removeService({
    required String vendorId,
    required String serviceId,
  }) async {
    try {
      await _firebaseService
          .vendorServicesCollection(vendorId)
          .doc(serviceId)
          .delete();

      _vendorServices.removeWhere((s) => s.serviceId == serviceId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Remove service error: $e');
      _error = 'Failed to remove service';
      notifyListeners();
      return false;
    }
  }

  // Check if vendor has a service
  bool hasService(String serviceId) {
    return _vendorServices.any((s) => s.serviceId == serviceId);
  }

  // Get vendor service by ID
  VendorServiceModel? getVendorService(String serviceId) {
    try {
      return _vendorServices.firstWhere((s) => s.serviceId == serviceId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
