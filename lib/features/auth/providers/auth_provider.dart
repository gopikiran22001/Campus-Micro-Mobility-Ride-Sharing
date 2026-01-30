import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../../../../core/constants/college_domains.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      // 1. Client-Side Domain Check
      if (!CollegeDomains.isAllowed(email)) {
        _error = 'Only verified college email IDs are allowed.';
        _setLoading(false);
        return false;
      }

      await _authService.signIn(email, password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    try {
      // 1. Client-Side Domain Check
      if (!CollegeDomains.isAllowed(email)) {
        _error = 'Only verified college email IDs are allowed.';
        _setLoading(false);
        return false;
      }

      await _authService.signUp(email, password);
      // Immediately send verification email
      await _authService.sendEmailVerification();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential.user;

      if (user != null) {
        // STRICT Client-Side Domain Check
        final email = user.email ?? '';
        if (!CollegeDomains.isAllowed(email)) {
          // Domain not allowed.
          // Force Sign Out immediately (Simulate blocking)
          await _authService.signOut();
          _error = 'Only verified college email IDs are allowed.';
          _setLoading(false);
          return false;
        }
      }

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'BLOCKING_FUNCTION_ERROR_RESPONSE') {
        _error = e.message;
      } else {
        _error = e.message ?? 'Google Sign In Failed';
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred during Google Sign In.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendEmailVerification();
  }
}
