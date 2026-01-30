import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RealLocationService {
  StreamController<LatLng>? _locationController;
  StreamSubscription<Position>? _positionSubscription;

  Stream<LatLng> get locationStream {
    _locationController ??= StreamController<LatLng>.broadcast();
    return _locationController!.stream;
  }

  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> startTracking() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) throw Exception('Location permission denied');

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _locationController?.add(LatLng(position.latitude, position.longitude));
    });
  }

  Future<LatLng?> getCurrentLocation() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;

    try {
      final position = await Geolocator.getCurrentPosition();
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController?.close();
    _locationController = null;
  }
}
