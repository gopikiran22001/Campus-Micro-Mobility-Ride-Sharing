import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ride_matching_service.dart';
import '../../../core/models/location_point.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/user_profile.dart';

class DebugMatchingScreen extends StatefulWidget {
  const DebugMatchingScreen({super.key});

  @override
  State<DebugMatchingScreen> createState() => _DebugMatchingScreenState();
}

class _DebugMatchingScreenState extends State<DebugMatchingScreen> {
  final _matchingService = RideMatchingService();
  final _profileService = ProfileService();
  List<UserProfile> _availableRiders = [];
  bool _isLoading = false;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableRiders();
  }

  Future<void> _loadAvailableRiders() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Loading available riders...';
    });

    try {
      final profile = context.read<ProfileProvider>().profile;
      if (profile == null) {
        setState(() {
          _debugInfo = 'No profile found';
          _isLoading = false;
        });
        return;
      }

      final riders = await _profileService.getAvailableRiders(profile.collegeDomain);
      
      setState(() {
        _availableRiders = riders;
        _debugInfo = 'Found ${riders.length} available riders in ${profile.collegeDomain}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading riders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMatching() async {
    setState(() {
      _isLoading = true;
      _debugInfo = 'Testing ride matching...';
    });

    try {
      final profile = context.read<ProfileProvider>().profile;
      if (profile == null) {
        setState(() {
          _debugInfo = 'No profile found';
          _isLoading = false;
        });
        return;
      }

      // Use current location as test student location
      final testLocation = LocationPoint(
        latitude: 28.6139,
        longitude: 77.2090,
        displayName: 'Test Location - Delhi',
      );

      final eligibleRiders = await _matchingService.findEligibleRiders(
        collegeDomain: profile.collegeDomain,
        studentLocation: testLocation,
      );

      String debugText = 'MATCHING TEST RESULTS:\n\n';
      debugText += 'College Domain: ${profile.collegeDomain}\n';
      debugText += 'Test Location: ${testLocation.latitude}, ${testLocation.longitude}\n\n';
      debugText += 'Total Available Riders: ${_availableRiders.length}\n';
      debugText += 'Eligible Riders: ${eligibleRiders.length}\n\n';

      for (int i = 0; i < _availableRiders.length; i++) {
        final rider = _availableRiders[i];
        debugText += 'RIDER ${i + 1}: ${rider.name}\n';
        debugText += '  - Vehicle: ${rider.vehicleType.name}\n';
        debugText += '  - Available: ${rider.isAvailable}\n';
        debugText += '  - Rider Mode: ${rider.isRiderMode}\n';
        debugText += '  - Has Route: ${rider.activeRoute != null}\n';
        
        if (rider.activeRoute != null) {
          debugText += '  - Route Start: ${rider.activeRoute!.startPoint.latitude}, ${rider.activeRoute!.startPoint.longitude}\n';
          debugText += '  - Route End: ${rider.activeRoute!.endPoint.latitude}, ${rider.activeRoute!.endPoint.longitude}\n';
          debugText += '  - Polyline Length: ${rider.activeRoute!.encodedPolyline.length} chars\n';
          
          final isCompatible = _matchingService.isStudentOnRiderRoute(
            studentLocation: testLocation,
            riderRoute: rider.activeRoute!,
          );
          debugText += '  - Route Compatible: $isCompatible\n';
        }
        
        if (rider.vehicleType == VehicleType.car) {
          debugText += '  - Available Seats: ${rider.availableSeats}\n';
        }
        debugText += '\n';
      }

      setState(() {
        _debugInfo = debugText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error testing matching: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Matching'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAvailableRiders,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadAvailableRiders,
                  child: const Text('Load Riders'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testMatching,
                  child: const Text('Test Matching'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _debugInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.white,
                      ),
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