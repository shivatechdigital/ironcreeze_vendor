import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ironcreze_vendor/services/fcm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/enums/auth_type.dart';
import '../core/constants/app_constants.dart';
import '../data/services/firebase_service.dart' hide debugPrint;

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  codeSent,
  error,
}

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;

  User? _user;
  User? get user => _user;

  String? _error;
  String? get error => _error;

  String? _verificationId;
  String? get verificationId => _verificationId;

  int? _resendToken;

  AuthType? _authType;
  AuthType? get authType => _authType;

  bool _isNewUser = false;
  bool get isNewUser => _isNewUser;

  AuthProvider() {
    _initAuth();
  }

  // ─────────────────────────────────────────────
  // Initialize Auth State
  // ─────────────────────────────────────────────
  Future<void> _initAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _firebaseService.auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        debugPrint('✅ Auth state: user logged in — ${user.uid}');
        _status = AuthStatus.authenticated;
        await _saveAuthState(true);
      } else {
        debugPrint('ℹ️ Auth state: no user');
        _status = AuthStatus.unauthenticated;
        await _saveAuthState(false);
      }
      notifyListeners();
    });
  }

  // Save Auth State to SharedPreferences
  Future<void> _saveAuthState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, isLoggedIn);
    if (isLoggedIn && _user != null) {
      await prefs.setString(AppConstants.keyUserId, _user!.uid);
      if (_authType != null) {
        await prefs.setString(AppConstants.keyAuthType, _authType!.value);
      }
    } else {
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyAuthType);
    }
  }

  // ─────────────────────────────────────────────
  // EMAIL AUTHENTICATION
  // ─────────────────────────────────────────────

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 signUpWithEmail: $email');
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final credential = await _firebaseService.auth
          .createUserWithEmailAndPassword(email: email, password: password);

      _user = credential.user;
      _authType = AuthType.email;
      _isNewUser = true;
      _status = AuthStatus.authenticated;
      notifyListeners();

      debugPrint('✅ signUpWithEmail success');
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      debugPrint('❌ signUpWithEmail exception: $e');
      _error = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('📧 signInWithEmail: $email');
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final credential = await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = credential.user;
      _authType = AuthType.email;
      _isNewUser = false;
      _status = AuthStatus.authenticated;
      notifyListeners();

      debugPrint('✅ signInWithEmail success');
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      debugPrint('❌ signInWithEmail exception: $e');
      _error = 'An unexpected error occurred';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // PHONE AUTHENTICATION
  // ✅ FIX: Completer se properly callback ka wait karo
  // ─────────────────────────────────────────────

  Future<bool> sendOTP({required String phoneNumber}) async {
    debugPrint('📱 ====== SEND OTP STARTED ======');
    debugPrint('📱 Phone: +91$phoneNumber');

    try {
      _status = AuthStatus.loading;
      _error = null;
      _verificationId = null;
      notifyListeners();

      // ✅ Completer — callback aane tak wait karo
      final completer = Completer<bool>();

      await _firebaseService.auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        timeout: const Duration(seconds: 120),
        forceResendingToken: _resendToken,

        // ✅ Android auto-verify
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ AUTO VERIFICATION COMPLETED');
          _authType = AuthType.phone;

          try {
            final userCredential = await _firebaseService.auth
                .signInWithCredential(credential);
            _user = userCredential.user;
            _isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
            _status = AuthStatus.authenticated;
            notifyListeners();
            if (!completer.isCompleted) completer.complete(true);
          } catch (e) {
            debugPrint('❌ Auto sign-in failed: $e');
            if (!completer.isCompleted) completer.complete(false);
          }
        },

        // ✅ FIX: sirf ek baar error set karo, phir complete karo
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ VERIFICATION FAILED: ${e.code} — ${e.message}');
          _handleAuthError(e);
          if (!completer.isCompleted) completer.complete(false);
        },

        // ✅ OTP bheja gaya
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📨 CODE SENT — verificationId: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken;
          _status = AuthStatus.codeSent;
          _error = null;
          notifyListeners();
          if (!completer.isCompleted) completer.complete(true);
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ AUTO RETRIEVAL TIMEOUT');
          if (_verificationId == null || _verificationId!.isEmpty) {
            _verificationId = verificationId;
            _status = AuthStatus.codeSent;
            notifyListeners();
          }
          if (!completer.isCompleted) completer.complete(true);
        },
      );

      // ✅ 60 second timeout — agar koi callback na aaye
      final result = await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint('⏱ TIMEOUT — no callback received in 60s');
          _error = 'Request timed out. Check internet and try again.';
          _status = AuthStatus.error;
          notifyListeners();
          return false;
        },
      );

      debugPrint('📱 ====== SEND OTP COMPLETED ======');
      debugPrint(
        '📱 Result: $result | Status: $_status | VID: $_verificationId',
      );

      return result;
    } catch (e) {
      debugPrint('💥 SEND OTP EXCEPTION: $e');
      _error = 'Failed to send OTP. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // VERIFY OTP
  // ─────────────────────────────────────────────

  Future<bool> verifyOTP({required String otp}) async {
    debugPrint('🔐 verifyOTP called — otp: $otp');

    try {
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      if (_verificationId == null || _verificationId!.isEmpty) {
        debugPrint('❌ verificationId is null/empty');
        _error = 'Session expired. Please request a new OTP.';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _firebaseService.auth.signInWithCredential(
        credential,
      );

      _user = userCredential.user;
      _authType = AuthType.phone;
      _isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      _status = AuthStatus.authenticated;
      _verificationId = null;
      notifyListeners();

      debugPrint('✅ OTP Verified — uid: ${_user?.uid}');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ verifyOTP FirebaseAuthException: ${e.code}');
      _handleAuthError(e);
      return false;
    } catch (e) {
      debugPrint('❌ verifyOTP exception: $e');
      _error = 'Invalid OTP. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // GOOGLE AUTHENTICATION
  // ─────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🟢 signInWithGoogle called');
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('ℹ️ Google sign in cancelled');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseService.auth.signInWithCredential(
        credential,
      );

      _user = userCredential.user;
      _authType = AuthType.google;
      _isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      _status = AuthStatus.authenticated;
      notifyListeners();

      debugPrint('✅ signInWithGoogle success — uid: ${_user?.uid}');
      return true;
    } catch (e) {
      debugPrint('❌ signInWithGoogle error: $e');
      _error = 'Google sign in failed. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────

  Future<bool> resetPassword({required String email}) async {
    try {
      debugPrint('🔑 resetPassword: $email');
      _status = AuthStatus.loading;
      _error = null;
      notifyListeners();

      await _firebaseService.auth.sendPasswordResetEmail(email: email);

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      debugPrint('✅ Reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      debugPrint('❌ resetPassword exception: $e');
      _error = 'Failed to send reset email. Please try again.';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // SIGN OUT
  // ─────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      debugPrint('👋 signOut called');
      await FcmService.deleteToken();
      await _googleSignIn.signOut();
      await _firebaseService.auth.signOut();

      _user = null;
      _authType = null;
      _isNewUser = false;
      _verificationId = null;
      _resendToken = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      debugPrint('✅ signOut success');
    } catch (e) {
      debugPrint('❌ signOut error: $e');
      _error = 'Failed to sign out';
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // ERROR HANDLING
  // ─────────────────────────────────────────────

  void _handleAuthError(FirebaseAuthException e) {
    debugPrint('❌ FirebaseAuthException: ${e.code} — ${e.message}');

    switch (e.code) {
      case 'weak-password':
        _error = 'The password is too weak.';
        break;
      case 'email-already-in-use':
        _error = 'An account already exists with this email.';
        break;
      case 'invalid-email':
        _error = 'Please enter a valid email address.';
        break;
      case 'user-not-found':
        _error = 'No account found with this email.';
        break;
      case 'wrong-password':
        _error = 'Incorrect password.';
        break;
      case 'user-disabled':
        _error = 'This account has been disabled.';
        break;
      case 'too-many-requests':
        _error = 'Too many attempts. Please try again later.';
        break;
      case 'invalid-phone-number':
        _error = 'Please enter a valid phone number.';
        break;
      case 'invalid-verification-code':
        _error = 'Invalid OTP. Please try again.';
        break;
      case 'invalid-verification-id':
        _error = 'Session expired. Please request a new OTP.';
        break;
      case 'session-expired':
        _error = 'OTP expired. Please request a new one.';
        break;
      case 'quota-exceeded':
        _error = 'SMS quota exceeded. Please try again later.';
        break;
      case 'network-request-failed':
        _error = 'Network error. Check your internet connection.';
        break;
      case 'app-not-authorized':
        _error = 'App not authorized. Please contact support.';
        break;
      case 'captcha-check-failed':
        _error = 'Verification failed. Please try again.';
        break;
      case 'missing-phone-number':
        _error = 'Please enter a phone number.';
        break;
      case 'operation-not-allowed':
        _error = 'Phone sign-in is not enabled. Contact support.';
        break;
      default:
        _error = e.message ?? 'An error occurred. Please try again.';
    }

    _status = AuthStatus.error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  bool get isEmailVerified => _user?.emailVerified ?? false;
  String? get userEmail => _user?.email;
  String? get userPhone => _user?.phoneNumber;
  String? get userDisplayName => _user?.displayName;
  String? get userPhotoUrl => _user?.photoURL;

  Future<bool> checkAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }
}
