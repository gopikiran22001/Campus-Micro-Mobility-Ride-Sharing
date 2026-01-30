import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/location_point.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/models/user_profile.dart';
import 'osm_location_picker_screen.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  final MapController _mapController = MapController();
  final _mapService = OsmMapService();
  LocationPoint? _startPoint;
  LocationPoint? _endPoint;
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  Map<String, dynamic>? _routeData;
  bool _isLoadingRoute = false;
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  Future<void> _selectStartPoint() async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          title: 'Select Start Point',
          initialLocation: _startPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _startPoint = result;
        _updateMarkers();
      });
      if (_endPoint != null) {
        await _fetchRoute();
      }
    }
  }

  Future<void> _selectEndPoint() async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          title: 'Select End Point',
          initialLocation: _endPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _endPoint = result;
        _updateMarkers();
      });
      if (_startPoint != null) {
        await _fetchRoute();
      }
    }
  }

  void _updateMarkers() {
    _markers.clear();
    if (_startPoint != null) {
      _markers.add(
        Marker(
          point: LatLng(_startPoint!.latitude, _startPoint!.longitude),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.trip_origin,
            color: Colors.green,
            size: 40,
          ),
        ),
      );
    }
    if (_endPoint != null) {
      _markers.add(
        Marker(
          point: LatLng(_endPoint!.latitude, _endPoint!.longitude),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    }
  }

  Future<void> _fetchRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final routeData = await _mapService.getRoute(_startPoint!, _endPoint!);
      if (routeData != null && mounted) {
        setState(() {
          _routeData = routeData;
          _polylines.clear();
          _polylines.add(
            Polyline(
              points: routeData['polyline'],
              color: AppColors.primary,
              strokeWidth: 5,
            ),
          );
          _isLoadingRoute = false;
        });

        if (routeData['polyline'].isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(routeData['polyline']);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load route: $e')),
        );
      }
    }
  }

  void _confirmRoute() {
    if (_startPoint == null || _endPoint == null || _routeData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end points')),
      );
      return;
    }

    final route = RiderRoute(
      startPoint: _startPoint!,
      endPoint: _endPoint!,
      encodedPolyline: _routeData!['encodedPolyline'],
      distanceMeters: _routeData!['distance'],
      durationSeconds: _routeData!['duration'],
    );

    Navigator.pop(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Route'),
        actions: [
          if (_routeData != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmRoute,
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campusgo',
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.trip_origin,
                            color: Colors.green,
                          ),
                          title: Text(
                            _startPoint?.displayName ?? 'Select Start Point',
                            style: TextStyle(
                              color: _startPoint == null
                                  ? AppColors.textSecondary
                                  : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: _selectStartPoint,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                          ),
                          title: Text(
                            _endPoint?.displayName ?? 'Select End Point',
                            style: TextStyle(
                              color: _endPoint == null
                                  ? AppColors.textSecondary
                                  : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: _selectEndPoint,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingRoute)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Loading route...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_routeData != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Icon(
                                Icons.straighten,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_routeData!['distance'] / 1000).toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Distance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(_routeData!['duration'] / 60).round()} min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Duration',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirmRoute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'Confirm Route',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
