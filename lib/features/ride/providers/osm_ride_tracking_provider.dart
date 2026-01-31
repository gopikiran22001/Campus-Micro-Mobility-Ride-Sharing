import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/real_time_location_service.dart';
import '../models/ride_model.dart';

class RideTrackingProvider extends ChangeNotifier {
  final RealTimeLocationService _realTimeLocationService = RealTimeLocationService();
  
  LatLng? _currentLocation;
  LatLng? _destinationLocation;
  List<LatLng> _routePolyline = [];
  int _estimatedTimeMinutes = 0;
  Map<String, dynamic>? _rideLocations;
  StreamSubscription? _locationSubscription;
  
  LatLng? get currentLocation => _currentLocation;
  LatLng? get destinationLocation => _destinationLocation;
  List<LatLng> get routePolyline => _routePolyline;
  int get estimatedTimeMinutes => _estimatedTimeMinutes;
  Map<String, dynamic>? get rideLocations => _rideLocations;
  bool get isTracking => _realTimeLocationService.isTracking;

  Future<void> startTracking(String userId, String rideId, Ride ride) async {
    _destinationLocation = LatLng(
      ride.destinationPoint.latitude,
      ride.destinationPoint.longitude,
    );
    
    await _realTimeLocationService.startTracking(userId, rideId);
    
    _locationSubscription = _realTimeLocationService
        .getRideLocations(rideId)
        .listen((locations) {
      _rideLocations = locations;
      
      if (locations != null && locations.containsKey(userId)) {
        final userLocation = locations[userId];
        _currentLocation = LatLng(
          userLocation['latitude'],
          userLocation['longitude'],
        );
      }
      
      notifyListeners();
    });
    
    notifyListeners();
  }
  
  LatLng? getRiderLocation(String riderId) {
    if (_rideLocations == null || !_rideLocations!.containsKey(riderId)) {
      return null;
    }
    
    final riderData = _rideLocations![riderId];
    return LatLng(riderData['latitude'], riderData['longitude']);
  }
  
  LatLng? getStudentLocation(String studentId) {
    if (_rideLocations == null || !_rideLocations!.containsKey(studentId)) {
      return null;
    }
    
    final studentData = _rideLocations![studentId];
    return LatLng(studentData['latitude'], studentData['longitude']);
  }
  
  void updateRoute(List<LatLng> polyline) {
    _routePolyline = polyline;
    notifyListeners();
  }
  
  void updateETA(int minutes) {
    _estimatedTimeMinutes = minutes;
    notifyListeners();
  }
  
  void stopTracking() {
    _realTimeLocationService.stopTracking();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _rideLocations = null;
    _currentLocation = null;
    _destinationLocation = null;
    _routePolyline = [];
    _estimatedTimeMinutes = 0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopTracking();
    _realTimeLocationService.dispose();
    super.dispose();
  }
}
