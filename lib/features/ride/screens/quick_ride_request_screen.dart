import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../../../core/models/location_point.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/services/real_location_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ride_provider.dart';

class QuickRideRequestScreen extends StatefulWidget {
  const QuickRideRequestScreen({super.key});

  @override
  State<QuickRideRequestScreen> createState() => _QuickRideRequestScreenState();
}

class _QuickRideRequestScreenState extends State<QuickRideRequestScreen> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _mapService = OsmMapService();
  final _locationService = RealLocationService();
  
  LocationPoint? _currentPickupLocation;
  LocationPoint? _destinationLocation;
  List<LocationPoint> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = true;
  String? _locationError;
  bool _showSearchResults = false;
  
  final List<Marker> _markers = [];
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    developer.log('\n🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴', name: 'QuickRideRequestScreen');
    developer.log('🔴 MAP SCREEN initState() CALLED', name: 'QuickRideRequestScreen');
    developer.log('🔴 This is the MAP screen with location tracking', name: 'QuickRideRequestScreen');
    developer.log('🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴', name: 'QuickRideRequestScreen');
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchResults = _searchFocusNode.hasFocus && _searchResults.isNotEmpty;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('\n🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠', name: 'QuickRideRequestScreen');
      developer.log('🟠 PostFrameCallback - NOW STARTING LOCATION TRACKING', name: 'QuickRideRequestScreen');
      developer.log('🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠🟠', name: 'QuickRideRequestScreen');
      _initializePickupLocation();
    });
    developer.log('🔴 MAP SCREEN initState() COMPLETED (location will start in PostFrameCallback)', name: 'QuickRideRequestScreen');
    developer.log('🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴🔴\n', name: 'QuickRideRequestScreen');
  }

  Future<void> _initializePickupLocation() async {
    developer.log('\n🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡', name: 'LocationTracking');
    developer.log('🟡 _initializePickupLocation() STARTED', name: 'LocationTracking');
    developer.log('🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡', name: 'LocationTracking');
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    developer.log('📍 Checking location permissions...', name: 'LocationTracking');
    final hasPermission = await _locationService.checkPermissions();
    developer.log('📍 Permission result: $hasPermission', name: 'LocationTracking');
    if (!hasPermission) {
      developer.log('❌ Location permission DENIED', name: 'LocationTracking');
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Location permission denied';
      });
      return;
    }

    developer.log('📍 Getting current location...', name: 'LocationTracking');
    final location = await _locationService.getCurrentLocation();
    developer.log('📍 Location result: ${location?.latitude}, ${location?.longitude}', name: 'LocationTracking');
    if (location == null) {
      developer.log('❌ Unable to get location', name: 'LocationTracking');
      setState(() {
        _isLoadingLocation = false;
        _locationError = 'Unable to get location';
      });
      return;
    }

    try {
      developer.log('🗺️ Reverse geocoding location...', name: 'LocationTracking');
      final pickupPoint = await _mapService.reverseGeocode(
        location.latitude,
        location.longitude,
      );
      developer.log('🗺️ Reverse geocode result: ${pickupPoint.displayName}', name: 'LocationTracking');
      
      if (mounted) {
        setState(() {
          _currentPickupLocation = pickupPoint;
          _isLoadingLocation = false;
        });
        _addPickupMarker(pickupPoint);
        developer.log('✅ Location tracking completed successfully', name: 'LocationTracking');
      }
    } catch (e) {
      developer.log('❌ Reverse geocode failed: $e', name: 'LocationTracking');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Failed to resolve location';
        });
      }
    }
    developer.log('🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡🟡', name: 'LocationTracking');
    developer.log('🟡 _initializePickupLocation() COMPLETED\n', name: 'LocationTracking');
  }

  void _addPickupMarker(LocationPoint location) {
    setState(() {
      _markers.removeWhere((m) => m.key == const Key('pickup'));
      _markers.add(
        Marker(
          key: const Key('pickup'),
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

  void _requestRide() {
    if (_currentPickupLocation == null || _destinationLocation == null) {
      return;
    }

    final user = context.read<AuthProvider>().user;
    final profile = context.read<ProfileProvider>().profile;

    if (user != null && profile != null) {
      context.read<RideProvider>().requestRide(
            studentId: user.uid,
            studentName: profile.name,
            destination: _destinationLocation!.displayName,
            collegeDomain: profile.collegeDomain,
            pickupPoint: _currentPickupLocation!,
            destinationPoint: _destinationLocation!,
          );
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
    developer.log('🔴 MAP SCREEN build() called', name: 'QuickRideRequestScreen');
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Destination'),
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
                        onPressed: _initializePickupLocation,
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
                          initialCenter: _currentPickupLocation != null
                              ? LatLng(_currentPickupLocation!.latitude, _currentPickupLocation!.longitude)
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
                          if (_currentPickupLocation != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: LatLng(_currentPickupLocation!.latitude, _currentPickupLocation!.longitude),
                                  radius: 80,
                                  useRadiusInMeter: true,
                                  color: Colors.blue.withValues(alpha: 0.15),
                                  borderColor: Colors.blue.withValues(alpha: 0.4),
                                  borderStrokeWidth: 2,
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
                                        hintText: 'Where to?',
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
                                  IconButton(
                                    icon: const Icon(Icons.person, color: Colors.black87),
                                    onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                                            onTap: () {
                                              _addDestinationMarker(result);
                                              _searchController.clear();
                                              setState(() {
                                                _searchResults = [];
                                                _showSearchResults = false;
                                              });
                                              FocusScope.of(context).unfocus();
                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                if (mounted) {
                                                  _mapController.move(LatLng(result.latitude, result.longitude), 25);
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                              ),
                          ],
                        ),
                      ),
                      if (!_showSearchResults)
                        Positioned(
                          right: 16,
                          bottom: _destinationLocation != null ? 200 : 100,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                heroTag: 'location',
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  if (_currentPickupLocation != null) {
                                    _mapController.move(
                                      LatLng(_currentPickupLocation!.latitude, _currentPickupLocation!.longitude),
                                      16,
                                    );
                                  }
                                },
                                child: const Icon(Icons.my_location, color: Colors.blue),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton(
                                heroTag: 'zoomIn',
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                                },
                                child: const Icon(Icons.add, color: Colors.black87),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton(
                                heroTag: 'zoomOut',
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: () {
                                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                                },
                                child: const Icon(Icons.remove, color: Colors.black87),
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
                                              'Pickup',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                            ),
                                            Text(
                                              _currentPickupLocation?.displayName.split(',').first ?? 'Current Location',
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
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _requestRide,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Request Ride',
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
