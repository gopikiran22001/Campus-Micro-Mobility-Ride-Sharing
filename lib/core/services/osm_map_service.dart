import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/location_point.dart';

class OsmMapService {
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';

  Future<List<LocationPoint>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=$query&format=json&limit=5',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CampusGo-RideSharing/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((item) {
          return LocationPoint(
            latitude: double.parse(item['lat']),
            longitude: double.parse(item['lon']),
            displayName: item['display_name'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search places: $e');
    }
  }

  Future<Map<String, dynamic>?> getRoute(
    LocationPoint start,
    LocationPoint end,
  ) async {
    try {
      final url = Uri.parse(
        '$_osrmBaseUrl/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = decodePolyline(route['geometry']);
          return {
            'polyline': polylinePoints,
            'encodedPolyline': route['geometry'],
            'distance': route['distance'].toInt(),
            'duration': route['duration'].toInt(),
          };
        }
      }
      throw Exception('Failed to get route: ${response.body}');
    } catch (e) {
      throw Exception('Failed to get route: $e');
    }
  }

  List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  bool isPointNearRoute(
    LocationPoint point,
    List<LatLng> routePolyline,
    double thresholdMeters,
  ) {
    for (var routePoint in routePolyline) {
      final distance = _calculateDistance(
        point.latitude,
        point.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance <= thresholdMeters) {
        return true;
      }
    }
    return false;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }
}
