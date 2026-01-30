import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/models/user_profile.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../models/ride_model.dart';
import 'osm_live_tracking_screen.dart';
import 'map_ride_request_screen.dart';
import 'osm_route_selection_screen.dart';

class RideHomeScreen extends StatefulWidget {
  const RideHomeScreen({super.key});

  @override
  State<RideHomeScreen> createState() => _RideHomeScreenState();
}

class _RideHomeScreenState extends State<RideHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileLoaded();
    });
  }

  Future<void> _ensureProfileLoaded() async {
    final profileProvider = context.read<ProfileProvider>();
    final authProvider = context.read<AuthProvider>();
    final rideProvider = context.read<RideProvider>();

    if (authProvider.user != null) {
      if (profileProvider.profile == null) {
        await profileProvider.loadProfile(authProvider.user!.uid);
      }

      if (mounted) {
        final profile = profileProvider.profile;
        if (profile == null) {
          context.go('/profile-setup');
        } else {
          // Start Listeners based on mode
          if (profile.isRiderMode) {
            rideProvider.startListeningToIncomingRequests(profile.id);
          } else {
            rideProvider.startListeningToActiveRide(profile.id);
          }
        }
      }
    }
  }

  Future<void> _toggleMode(
    bool isRider,
    String userId,
    ProfileProvider pProvider,
  ) async {
    await pProvider.toggleRiderMode(isRider);
    if (!mounted) return;
    final rProvider = context.read<RideProvider>();
    if (isRider) {
      rProvider.startListeningToIncomingRequests(userId);
    } else {
      rProvider.startListeningToActiveRide(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final profile = profileProvider.profile;

        if (profileProvider.isLoading || profile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              profile.isRiderMode ? AppStrings.riderMode : AppStrings.homeTitle,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
          body: profile.isRiderMode
              ? _buildRiderView(context, profileProvider)
              : _buildStudentView(context, profileProvider),

          floatingActionButton: profile.hasVehicle
              ? FloatingActionButton.extended(
                  onPressed: () {
                    _toggleMode(
                      !profile.isRiderMode,
                      profile.id,
                      profileProvider,
                    );
                  },
                  icon: Icon(
                    profile.isRiderMode
                        ? Icons.directions_walk
                        : Icons.motorcycle,
                  ),
                  label: Text(
                    profile.isRiderMode
                        ? 'Switch to Passenger'
                        : 'Switch to Rider',
                  ),
                  backgroundColor: profile.isRiderMode
                      ? AppColors.secondary
                      : AppColors.primary,
                )
              : null,
        );
      },
    );
  }

  Widget _buildStudentView(
    BuildContext context,
    ProfileProvider profileProvider,
  ) {
    if (context.watch<RideProvider>().activeRide != null) {
      return _buildActiveRideView(context);
    }

    final destinationController = TextEditingController();
    String selectedZone = 'Central';
    RideTime selectedTime = RideTime.now;
    VehicleType selectedVehicleType = VehicleType.bike;
    int requestedSeats = 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.requestRide,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find a ride to your destination',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedZone,
                          decoration: InputDecoration(
                            labelText: 'Pickup Zone',
                            prefixIcon: const Icon(
                              Icons.location_city,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Central',
                              child: Text('Central Campus'),
                            ),
                            DropdownMenuItem(
                              value: 'North',
                              child: Text('North Campus'),
                            ),
                            DropdownMenuItem(
                              value: 'South',
                              child: Text('South Campus'),
                            ),
                            DropdownMenuItem(
                              value: 'East',
                              child: Text('East Campus'),
                            ),
                            DropdownMenuItem(
                              value: 'West',
                              child: Text('West Campus'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedZone = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<RideTime>(
                          value: selectedTime,
                          decoration: InputDecoration(
                            labelText: 'When do you need a ride?',
                            prefixIcon: const Icon(
                              Icons.access_time,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: RideTime.now,
                              child: Text('Now (Immediate)'),
                            ),
                            DropdownMenuItem(
                              value: RideTime.soon,
                              child: Text('Next 30 minutes'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedTime = value);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<VehicleType>(
                          value: selectedVehicleType,
                          decoration: InputDecoration(
                            labelText: 'Vehicle Type',
                            prefixIcon: const Icon(
                              Icons.directions_car,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: VehicleType.bike,
                              child: Text('Bike (1 seat)'),
                            ),
                            DropdownMenuItem(
                              value: VehicleType.car,
                              child: Text('Car (multi-seat)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedVehicleType = value;
                                if (value == VehicleType.bike) {
                                  requestedSeats = 1;
                                }
                              });
                            }
                          },
                        ),
                        if (selectedVehicleType == VehicleType.car) ...[
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            value: requestedSeats,
                            decoration: InputDecoration(
                              labelText: 'Number of Seats',
                              prefixIcon: const Icon(
                                Icons.event_seat,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('1 seat')),
                              DropdownMenuItem(value: 2, child: Text('2 seats')),
                              DropdownMenuItem(value: 3, child: Text('3 seats')),
                              DropdownMenuItem(value: 4, child: Text('4 seats')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => requestedSeats = value);
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextField(
                          controller: destinationController,
                          decoration: InputDecoration(
                            hintText: 'Enter Destination',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapRideRequestScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.map, size: 24),
                    label: const Text(
                      'Request Ride with Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveRideView(BuildContext context) {
    final rideProvider = context.watch<RideProvider>();
    final ride = rideProvider.activeRide;
    final isRider =
        context.read<ProfileProvider>().profile?.isRiderMode ?? false;

    if (ride == null) return const SizedBox.shrink();

    String statusMsg = '';
    IconData statusIcon = Icons.directions_car;
    Color statusColor = AppColors.primary;

    if (isRider) {
      switch (ride.status) {
        case RideStatus.accepted:
          statusMsg = 'Picking up ${ride.studentName}';
          statusIcon = Icons.navigation;
          statusColor = AppColors.info;
          break;
        case RideStatus.arrived:
          statusMsg = 'Waiting for ${ride.studentName}';
          statusIcon = Icons.person_pin_circle;
          statusColor = AppColors.warning;
          break;
        case RideStatus.started:
          statusMsg = 'Driving to ${ride.destination}';
          statusIcon = Icons.motorcycle;
          statusColor = AppColors.success;
          break;
        default:
          statusMsg = 'Active Job';
      }
    } else {
      switch (ride.status) {
        case RideStatus.searching:
          statusMsg = 'Searching for nearby riders...';
          statusIcon = Icons.search;
          statusColor = AppColors.info;
          break;
        case RideStatus.requested:
          statusMsg = 'Waiting for rider to accept...';
          statusIcon = Icons.hourglass_empty;
          statusColor = AppColors.warning;
          break;
        case RideStatus.accepted:
          statusMsg = 'Ride Confirmed! ${ride.riderName} is coming.';
          statusIcon = Icons.check_circle;
          statusColor = AppColors.success;
          break;
        case RideStatus.no_match:
          statusMsg = 'No riders available';
          statusIcon = Icons.error_outline;
          statusColor = AppColors.error;
          break;
        default:
          statusMsg = 'Ride in progress';
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.surface,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ride.status == RideStatus.searching)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: const CircularProgressIndicator(
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        size: 64,
                        color: statusColor,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    statusMsg,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (isRider)
                    _buildInfoCard(
                      icon: Icons.person,
                      label: 'Passenger',
                      value: ride.studentName,
                    )
                  else if (ride.riderName != null &&
                      ride.status == RideStatus.accepted)
                    _buildInfoCard(
                      icon: Icons.motorcycle,
                      label: 'Rider',
                      value: ride.riderName!,
                    ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    label: 'Destination',
                    value: ride.destination,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_city,
                    label: 'Zone',
                    value: '${ride.zone} Campus',
                  ),
                  const SizedBox(height: 32),
                  if (!isRider && ride.status == RideStatus.no_match) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'We couldn\'t find any available riders in your zone at this time.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try again in a few minutes or select a different zone.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          rideProvider.cancelRide(
                            ride,
                            'No riders available - retrying',
                            context.read<AuthProvider>().user?.uid ?? '',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text(
                          'Try Again',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                  if (!isRider &&
                      ride.status == RideStatus.accepted &&
                      ride.riderName != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OsmLiveTrackingScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.map),
                        label: const Text(
                          'Track Rider',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (!isRider &&
                      (ride.status == RideStatus.searching ||
                          ride.status == RideStatus.requested))
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showCancellationDialog(context, ride, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.close, color: AppColors.error),
                        label: const Text(
                          'Cancel Request',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (isRider && ride.status == RideStatus.accepted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => rideProvider.completeRide(ride),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Complete Ride',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderView(BuildContext context, ProfileProvider provider) {
    final isAvailable = provider.profile?.isAvailable ?? false;
    final rideProvider = context.watch<RideProvider>();
    final activeRide = rideProvider.activeRide;
    final requests = rideProvider.incomingRequests;

    if (activeRide != null) {
      return _buildActiveRideView(context);
    }

    if (requests.isNotEmpty && isAvailable) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Incoming Requests',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${requests.length} ${requests.length == 1 ? 'rider' : 'riders'} waiting',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.studentName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${req.zone} Campus',
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
                                    req.destination,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      context.read<RideProvider>().skipRide(req),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.error,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.error,
                                  ),
                                  label: const Text(
                                    'Skip',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      context.read<RideProvider>().acceptRide(req),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Accept'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.textSecondary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAvailable
                          ? Icons.wifi_tethering
                          : Icons.wifi_tethering_off,
                      size: 80,
                      color: isAvailable
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              isAvailable ? AppStrings.online : AppStrings.offline,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              isAvailable
                  ? 'Waiting for ride requests...'
                  : 'Toggle switch to start accepting rides',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Accepting Rides',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  isAvailable ? 'You are online' : 'You are offline',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                value: isAvailable,
                onChanged: (val) {
                  _toggleMode(val, provider.profile!.id, provider);
                },
                activeColor: AppColors.success,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (isAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final route = await Navigator.push<RiderRoute>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RouteSelectionScreen(),
                        ),
                      );
                      if (route != null && mounted) {
                        await context
                            .read<RideProvider>()
                            .setRiderRoute(provider.profile!.id, route);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Route set successfully'),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.route),
                    label: Text(
                      provider.profile?.activeRoute != null
                          ? 'Update Route'
                          : 'Set Route',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            if (isAvailable && provider.profile?.activeRoute != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Route: ${provider.profile!.activeRoute!.startPoint.displayName} → ${provider.profile!.activeRoute!.endPoint.displayName}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        await context
                            .read<RideProvider>()
                            .clearRiderRoute(provider.profile!.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Route cleared'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Route'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCancellationDialog(
    BuildContext context,
    Ride ride,
    bool isRider,
  ) async {
    String? selectedReason;
    final reasons = isRider
        ? [
            'Student not at pickup location',
            'Cannot reach destination',
            'Emergency',
            'Other',
          ]
        : ['Found another ride', 'Changed plans', 'Taking too long', 'Other'];

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Ride'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please select a reason for cancellation:'),
              const SizedBox(height: 16),
              ...reasons.map((reason) {
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) {
                    selectedReason = value;
                    Navigator.of(context).pop(value);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep Ride'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final userId = context.read<AuthProvider>().user?.uid ?? '';
      await context.read<RideProvider>().cancelRide(ride, result, userId);
    }
  }
}
