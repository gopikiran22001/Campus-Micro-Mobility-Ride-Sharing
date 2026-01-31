import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/osm_ride_tracking_provider.dart';
import '../providers/ride_provider.dart';

class OsmLiveTrackingScreen extends StatefulWidget {
  const OsmLiveTrackingScreen({super.key});

  @override
  State<OsmLiveTrackingScreen> createState() => _OsmLiveTrackingScreenState();
}

class _OsmLiveTrackingScreenState extends State<OsmLiveTrackingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Tracking will be started from ride_home_screen when ride is accepted
  }

  @override
  void dispose() {
    context.read<RideTrackingProvider>().stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: AppColors.surface,
      ),
      body: Consumer2<RideTrackingProvider, RideProvider>(
        builder: (context, trackingProvider, rideProvider, _) {
          final ride = rideProvider.activeRide;
          
          if (ride == null) {
            return const Center(child: Text('No active ride'));
          }

          final markers = <Marker>[];
          
          // Get rider and student locations from real-time tracking
          LatLng? riderLocation;
          LatLng? studentLocation;
          
          if (ride.riderId != null) {
            riderLocation = trackingProvider.getRiderLocation(ride.riderId!);
          }
          studentLocation = trackingProvider.getStudentLocation(ride.studentId);
          
          // Add rider marker (motorcycle icon)
          if (riderLocation != null) {
            markers.add(
              Marker(
                point: riderLocation,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.motorcycle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            );
          }
          
          // Add student marker (person icon)
          if (studentLocation != null) {
            markers.add(
              Marker(
                point: studentLocation,
                width: 50,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            );
          }

          // Add destination marker
          markers.add(
            Marker(
              point: LatLng(
                ride.destinationPoint.latitude,
                ride.destinationPoint.longitude,
              ),
              width: 50,
              height: 50,
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 50,
              ),
            ),
          );
          
          // Use rider location or student location as center
          final centerLocation = riderLocation ?? studentLocation ?? 
              LatLng(ride.pickupPoint.latitude, ride.pickupPoint.longitude);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: centerLocation,
                  initialZoom: 15,
                  minZoom: 10,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.campusgo',
                  ),
                  if (trackingProvider.routePolyline.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: trackingProvider.routePolyline,
                          color: AppColors.primary.withValues(alpha: 0.7),
                          strokeWidth: 6,
                          borderColor: Colors.white,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (riderLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: riderLocation,
                          radius: 15,
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (studentLocation != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: studentLocation,
                          radius: 12,
                          color: AppColors.success.withValues(alpha: 0.3),
                          borderColor: AppColors.success,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
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
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rider on the way',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ETA: ${trackingProvider.estimatedTimeMinutes} min',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ride.riderName ?? 'Rider',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Rider',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ride.destination,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
