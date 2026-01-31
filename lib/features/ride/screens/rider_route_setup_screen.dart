import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/models/location_point.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/services/real_location_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/user_profile.dart';

class RiderRouteSetupScreen extends StatefulWidget {
  const RiderRouteSetupScreen({super.key});

  @override
  State<RiderRouteSetupScreen> createState() => _RiderRouteSetupScreenState();
}

class _RiderRouteSetupScreenState extends State<RiderRouteSetupScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _mapService = OsmMapService();
  final _locationService = RealLocationService();
  
  LocationPoint? _currentLocation;
  LocationPoint? _destinationLocation;
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  String? _locationError;
  bool _showSearchResults = false;
  int _availableSeats = 1;
  List<LatLng> _routePolyline = [];
  
  final List<Marker> _markers = [];
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchResults = _searchFocusNode.hasFocus && _searchResults.isNotEmpty;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCurrentLocation();
      _initializeSeats();
    });
  }

  void _initializeSeats() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null && profile.vehicleType == VehicleType.car) {
      setState(() {
        _availableSeats = profile.carSeats ?? 1;
      });
    }
  }

  Future<void> _initializeCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    final hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location permission denied';
      });
      return;
    }

    final location = await _locationService.getCurrentLocation();
    if (location == null) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Unable to get location';
      });
      return;
    }

    try {
      final currentPoint = await _mapService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = currentPoint;
          _isLoadingLocation = false;
        });
        _addStartMarker(currentPoint);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Failed to resolve location';
        });
      }
    }
  }

  void _addStartMarker(LocationPoint location) {
    setState(() {
      _markers.removeWhere((m) => m.key == const Key('start'));
      _markers.add(
        Marker(
          key: const Key('start'),
          point: LatLng(location.latitude, location.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    });
  }

  void _addDestinationMarker(LocationPoint location) {
    setState(() {
      _markers.removeWhere((m) => m.key == const Key('destination'));
      _markers.add(
        Marker(
          key: const Key('destination'),
          point: LatLng(location.latitude, location.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
      _destinationLocation = location;
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = false;
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
          _showSearchResults = results.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showSearchResults = false;
        });
      }
    }
  }

  Future<void> _startRiding() async {
    if (_currentLocation == null || _destinationLocation == null) {
      return;
    }

    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;

    try {
      final route = await _mapService.getRoute(
        _currentLocation!,
        _destinationLocation!,
      );

      if (route == null) {
        throw Exception('Failed to get route');
      }

      final riderRoute = RiderRoute(
        startPoint: _currentLocation!,
        endPoint: _destinationLocation!,
        encodedPolyline: route['encodedPolyline'] ?? '',
        distanceMeters: route['distance'] ?? 0,
        durationSeconds: route['duration'] ?? 0,
      );

      if (!mounted) return;
      await context.read<ProfileProvider>().updateProfile(
        profile.copyWith(
          isAvailable: true,
          availableSeats: profile.vehicleType == VehicleType.car ? _availableSeats : null,
          activeRoute: riderRoute,
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set route: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final isCar = profile?.vehicleType == VehicleType.car;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Set Your Route'),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _locationError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_locationError!),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initializeCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _showSearchResults = false);
                  },
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation != null
                              ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                              : _defaultCenter,
                          initialZoom: 17,
                          onTap: (_, __) {
                            FocusScope.of(context).unfocus();
                            setState(() => _showSearchResults = false);
                          },
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
                                  point: LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
                                  radius: 80,
                                  useRadiusInMeter: true,
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderColor: Colors.blue.withValues(alpha: 0.4),
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          if (_routePolyline.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: _routePolyline,
                                  strokeWidth: 4,
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      focusNode: _searchFocusNode,
                                      style: const TextStyle(color: Colors.white, fontSize: 16),
                                      decoration: InputDecoration(
                                        hintText: 'Where are you going?',
                                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                                        border: InputBorder.none,
                                        suffixIcon: _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, color: Colors.grey),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchResults = [];
                                                    _showSearchResults = false;
                                                  });
                                                  FocusScope.of(context).unfocus();
                                                },
                                              )
                                            : null,
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                        if (value.length > 2) {
                                          _searchPlaces(value);
                                        } else {
                                          setState(() {
                                            _searchResults = [];
                                            _showSearchResults = false;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_showSearchResults)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                constraints: const BoxConstraints(maxHeight: 300),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: _isSearching
                                    ? const Center(child: CircularProgressIndicator())
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        itemCount: _searchResults.length,
                                        separatorBuilder: (_, __) => const Divider(height: 1),
                                        itemBuilder: (context, index) {
                                          final result = _searchResults[index];
                                          return ListTile(
                                            leading: const Icon(Icons.location_on, color: Colors.red),
                                            title: Text(
                                              result.displayName.split(',').first,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              result.displayName,
                                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () async {
                                              _addDestinationMarker(result);
                                              _searchController.clear();
                                              setState(() {
                                                _searchResults = [];
                                                _showSearchResults = false;
                                              });
                                              FocusScope.of(context).unfocus();
                                              
                                              if (_currentLocation != null) {
                                                try {
                                                  final route = await _mapService.getRoute(
                                                    _currentLocation!,
                                                    result,
                                                  );
                                                  if (route != null && mounted) {
                                                    setState(() {
                                                      _routePolyline = route['polyline'] ?? [];
                                                    });
                                                    
                                                    Future.delayed(const Duration(milliseconds: 100), () {
                                                      if (mounted && _routePolyline.isNotEmpty) {
                                                        final bounds = LatLngBounds.fromPoints(_routePolyline);
                                                        _mapController.fitCamera(
                                                          CameraFit.bounds(
                                                            bounds: bounds,
                                                            padding: const EdgeInsets.all(50),
                                                          ),
                                                        );
                                                      }
                                                    });
                                                  }
                                                } catch (e) {
                                                  // Ignore route error
                                                }
                                              }
                                            },
                                          );
                                        },
                                      ),
                              ),
                          ],
                        ),
                      ),
                      if (_destinationLocation != null && !_showSearchResults)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, -4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.trip_origin, color: Colors.green, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Starting Point',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            Text(
                                              _currentLocation?.displayName.split(',').first ?? 'Current Location',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Destination',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            Text(
                                              _destinationLocation!.displayName.split(',').first,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isCar) ...[
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        const Icon(Icons.airline_seat_recline_normal, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Available Seats: $_availableSeats',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: _availableSeats > 1
                                              ? () => setState(() => _availableSeats--)
                                              : null,
                                          icon: const Icon(Icons.remove_circle_outline),
                                          color: AppColors.primary,
                                        ),
                                        IconButton(
                                          onPressed: _availableSeats < (profile?.carSeats ?? 4)
                                              ? () => setState(() => _availableSeats++)
                                              : null,
                                          icon: const Icon(Icons.add_circle_outline),
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _startRiding,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Start Riding',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                ),
    );
  }
}
