import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/profile_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile(userId);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createOrUpdateProfile(UserProfile profile) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _profileService.createProfile(profile);
      _profile = profile;
    } catch (e) {
      debugPrint('Error creating profile: $e');
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
      isAvailable: isActive, // Default to available if mode is active
    );

    // Optimistic update
    _profile = updatedProfile;
    notifyListeners();

    try {
      await _profileService.updateProfile(updatedProfile);
    } catch (e) {
      // Revert if error
      _profile = _profile!.copyWith(isRiderMode: !isActive);
      notifyListeners();
    }
  }
}
