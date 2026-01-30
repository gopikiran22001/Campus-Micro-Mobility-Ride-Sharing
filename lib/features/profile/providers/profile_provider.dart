import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile(userId);
    } catch (e) {
      _error = 'Failed to load profile: $e';
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrUpdateProfile(UserProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _profileService.createProfile(profile);
      _profile = profile;
    } catch (e) {
      _error = 'Failed to save profile: $e';
      debugPrint('Error creating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _profileService.updateProfile(profile);
      _profile = profile;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      debugPrint('Error updating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRiderMode(bool isActive) async {
    if (_profile == null) return;

    final updatedProfile = _profile!.copyWith(
      isRiderMode: isActive,
      isAvailable: isActive,
    );

    _profile = updatedProfile;
    notifyListeners();

    try {
      await _profileService.updateProfile(updatedProfile);
    } catch (e) {
      _profile = _profile!.copyWith(isRiderMode: !isActive);
      _error = 'Failed to toggle rider mode: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
