import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/location_point.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/services/real_location_service.dart';
import '../../../core/constants/app_colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LocationPoint? initialLocation;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initialLocation,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _mapService = OsmMapService();
  final _locationService = RealLocationService();
  LocationPoint? _selectedLocation;
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  final List<Marker> _markers = [];
  LatLng? _currentLocation;
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _addMarker(widget.initialLocation!);
    }
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() => _currentLocation = location);
      if (widget.initialLocation == null) {
        _mapController.move(location, 15);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationService.dispose();
    super.dispose();
  }

  void _addMarker(LocationPoint location) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      _selectedLocation = location;
    });
    _mapController.move(
      LatLng(location.latitude, location.longitude),
      15,
    );
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _mapService.searchPlaces(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    final location = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      displayName: 'Selected Location',
    );
    _addMarker(location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_selectedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => Navigator.pop(context, _selectedLocation),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation != null
                  ? LatLng(
                      widget.initialLocation!.latitude,
                      widget.initialLocation!.longitude,
                    )
                  : _defaultCenter,
              initialZoom: 14,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campusgo',
              ),
              if (_currentLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation!,
                      radius: 8,
                      color: Colors.blue.withOpacity(0.7),
                      borderColor: Colors.white,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
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
            bottom: 100,
            right: 16,
            child: Column(
              children: [
                if (_currentLocation != null)
                  FloatingActionButton(
                    heroTag: 'myLocation',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(_currentLocation!, 15);
                    },
                    child: const Icon(Icons.my_location, color: AppColors.primary),
                  ),
              ],
            ),
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _isSearching = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) {
                      if (value.length > 2) {
                        _searchPlaces(value);
                      }
                    },
                  ),
                ),
                if (_isSearching)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Card(
                    elevation: 8,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              result.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _addMarker(result);
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selectedLocation != null)
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
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation!.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, _selectedLocation),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Location',
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
