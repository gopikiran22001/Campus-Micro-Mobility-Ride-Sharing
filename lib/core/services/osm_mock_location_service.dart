import 'dart:async';
import 'package:latlong2/latlong.dart';

class MockLocationService {
  static final MockLocationService _instance = MockLocationService._internal();
  factory MockLocationService() => _instance;
  MockLocationService._internal();

  Timer? _locationTimer;
  int _currentIndex = 0;
  final StreamController<LatLng> _locationController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationController.stream;

  final List<LatLng> _mockRoute = [
    const LatLng(12.9716, 77.5946),
    const LatLng(12.9726, 77.5956),
    const LatLng(12.9736, 77.5966),
    const LatLng(12.9746, 77.5976),
    const LatLng(12.9756, 77.5986),
    const LatLng(12.9766, 77.5996),
    const LatLng(12.9776, 77.6006),
    const LatLng(12.9786, 77.6016),
    const LatLng(12.9796, 77.6026),
    const LatLng(12.9806, 77.6036),
  ];

  void startTracking() {
    _currentIndex = 0;
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentIndex < _mockRoute.length) {
        _locationController.add(_mockRoute[_currentIndex]);
        _currentIndex++;
      } else {
        _locationController.add(_mockRoute.last);
      }
    });
  }

  void stopTracking() {
    _locationTimer?.cancel();
    _currentIndex = 0;
  }

  LatLng get currentLocation =>
      _currentIndex > 0 && _currentIndex <= _mockRoute.length
          ? _mockRoute[_currentIndex - 1]
          : _mockRoute.first;

  LatLng get destination => _mockRoute.last;

  List<LatLng> get route => _mockRoute;

  void dispose() {
    _locationTimer?.cancel();
    _locationController.close();
  }
}
