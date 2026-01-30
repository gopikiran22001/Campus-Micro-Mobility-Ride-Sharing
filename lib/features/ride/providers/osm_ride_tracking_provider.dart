import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/real_location_service.dart';

class RideTrackingProvider extends ChangeNotifier {
  final RealLocationService _locationService = RealLocationService();
  StreamSubscription<LatLng>? _locationSubscription;

  LatLng? _currentRiderLocation;
  LatLng? get currentLocation => _currentRiderLocation;

  LatLng? _destinationLocation;
  LatLng? get destinationLocation => _destinationLocation;

  List<LatLng> _routePolyline = [];
  List<LatLng> get routePolyline => _routePolyline;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  int _estimatedTimeMinutes = 5;
  int get estimatedTimeMinutes => _estimatedTimeMinutes;

  void startTracking() async {
    if (_isTracking) return;

    try {
      _isTracking = true;
      await _locationService.startTracking();

      _locationSubscription = _locationService.locationStream.listen((location) {
        _currentRiderLocation = location;
        _calculateETA();
        notifyListeners();
      });

      final currentLoc = await _locationService.getCurrentLocation();
      if (currentLoc != null) {
        _currentRiderLocation = currentLoc;
        notifyListeners();
      }
    } catch (e) {
      _isTracking = false;
      debugPrint('Location tracking error: $e');
    }
  }

  void stopTracking() {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationService.stopTracking();
    _routePolyline = [];
    _currentRiderLocation = null;
    _destinationLocation = null;
    notifyListeners();
  }

  void _calculateETA() {
    _estimatedTimeMinutes = 5;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
