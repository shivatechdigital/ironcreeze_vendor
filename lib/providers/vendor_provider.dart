import 'dart:io';
import 'package:flutter/material.dart';
import '../data/services/firebase_service.dart' hide debugPrint;
import '../data/models/vendor_model.dart';
import '../core/enums/vendor_status.dart';

enum VendorState { initial, loading, loaded, error }

class VendorProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  VendorState _state = VendorState.initial;
  VendorState get state => _state;

  VendorModel? _vendor;
  VendorModel? get vendor => _vendor;

  String? _error;
  String? get error => _error;

  bool get isOnline => _vendor?.isOnline ?? false;
  VendorStatus get vendorStatus => _vendor?.status ?? VendorStatus.pending;
  bool get isApproved => vendorStatus == VendorStatus.approved;
  bool get isPending => vendorStatus == VendorStatus.pending;
  bool get isRejected => vendorStatus == VendorStatus.rejected;

  // ═══════════════════════════════════════════════════════════════
  // FETCH VENDOR
  // ═══════════════════════════════════════════════════════════════

  Future<void> fetchVendor(String vendorId) async {
    try {
      _state = VendorState.loading;
      notifyListeners();

      final doc = await _firebaseService.vendorDoc(vendorId).get();

      if (doc.exists) {
        _vendor = VendorModel.fromFirestore(doc);
        _state = VendorState.loaded;
      } else {
        _vendor = null;
        _state = VendorState.loaded;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch vendor error: $e');
      _error = 'Failed to fetch vendor data';
      _state = VendorState.error;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CHECK VENDOR EXISTS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> checkVendorExists(String vendorId) async {
    try {
      final doc = await _firebaseService.vendorDoc(vendorId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Check vendor exists error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE VENDOR
  // ═══════════════════════════════════════════════════════════════

  Future<bool> createVendor(VendorModel vendor) async {
    try {
      _state = VendorState.loading;
      notifyListeners();

      await _firebaseService.vendorDoc(vendor.uid).set(vendor.toFirestore());
      _vendor = vendor;
      _state = VendorState.loaded;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Create vendor error: $e');
      _error = 'Failed to create vendor profile';
      _state = VendorState.error;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPDATE VENDOR
  // ═══════════════════════════════════════════════════════════════

  Future<bool> updateVendor(Map<String, dynamic> data) async {
    try {
      if (_vendor == null) return false;

      _state = VendorState.loading;
      notifyListeners();

      await _firebaseService.vendorDoc(_vendor!.uid).update(data);
      await fetchVendor(_vendor!.uid);

      return true;
    } catch (e) {
      debugPrint('Update vendor error: $e');
      _error = 'Failed to update vendor profile';
      _state = VendorState.error;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE ONLINE STATUS
  // ═══════════════════════════════════════════════════════════════

  Future<bool> toggleOnlineStatus() async {
    try {
      if (_vendor == null) return false;

      final newStatus = !_vendor!.isOnline;
      await _firebaseService.vendorDoc(_vendor!.uid).update({
        'isOnline': newStatus,
      });

      _vendor = _vendor!.copyWith(isOnline: newStatus);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Toggle online status error: $e');
      _error = 'Failed to update status';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPLOAD PROFILE IMAGE
  // ═══════════════════════════════════════════════════════════════

  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (_vendor == null) return null;

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _firebaseService.profileImageRef(_vendor!.uid, fileName);

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      await _firebaseService.vendorDoc(_vendor!.uid).update({
        'profileImage': url,
      });

      _vendor = _vendor!.copyWith(profileImage: url);
      notifyListeners();

      return url;
    } catch (e) {
      debugPrint('Upload profile image error: $e');
      _error = 'Failed to upload image';
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // UPLOAD DOCUMENT
  // ═══════════════════════════════════════════════════════════════

  Future<String?> uploadDocument(File file, String type) async {
    try {
      if (_firebaseService.currentUserId == null) return null;

      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _firebaseService.documentRef(
        _firebaseService.currentUserId!,
        fileName,
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      debugPrint('Upload document error: $e');
      _error = 'Failed to upload document';
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LISTEN TO VENDOR STATUS (REAL-TIME)
  // ═══════════════════════════════════════════════════════════════

  void listenToVendorStatus(String vendorId) {
    _firebaseService
        .vendorDoc(vendorId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              _vendor = VendorModel.fromFirestore(doc);
              _state = VendorState.loaded;
              notifyListeners();
            }
          },
          onError: (e) {
            debugPrint('Listen to vendor status error: $e');
          },
        );
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR DATA
  // ═══════════════════════════════════════════════════════════════

  void clearVendor() {
    _vendor = null;
    _state = VendorState.initial;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
