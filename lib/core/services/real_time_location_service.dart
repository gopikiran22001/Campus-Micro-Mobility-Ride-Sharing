import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RealTimeLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _locationSubscription;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startTracking(String userId, String rideId) async {
    if (_isTracking) return;

    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateLocationInFirestore(userId, rideId, position);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );
  }

  Future<void> _updateLocationInFirestore(
    String userId,
    String rideId,
    Position position,
  ) async {
    try {
      await _firestore.collection('ride_locations').doc(rideId).set({
        userId: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
          'heading': position.heading,
          'speed': position.speed,
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Stream<Map<String, dynamic>?> getRideLocations(String rideId) {
    return _firestore
        .collection('ride_locations')
        .doc(rideId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  void stopTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
  }

  void dispose() {
    stopTracking();
  }
}