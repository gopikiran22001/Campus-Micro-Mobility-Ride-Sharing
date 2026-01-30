import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../models/ride_model.dart';

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
                onPressed: () {
                  // Navigate to Profile Details (Phase 2 or later in Phase 1)
                },
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 64,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  AppStrings.requestRide,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 32),

                // Zone Selection
                DropdownButtonFormField<String>(
                  value: selectedZone,
                  decoration: InputDecoration(
                    labelText: 'Pickup Zone',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    DropdownMenuItem(value: 'East', child: Text('East Campus')),
                    DropdownMenuItem(value: 'West', child: Text('West Campus')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedZone = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Time Selection
                DropdownButtonFormField<RideTime>(
                  value: selectedTime,
                  decoration: InputDecoration(
                    labelText: 'When do you need a ride?',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 16),

                // Destination
                TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    hintText: 'Enter Destination',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final dest = destinationController.text.trim();
                      if (dest.isNotEmpty) {
                        final user = context.read<AuthProvider>().user;
                        final profile = profileProvider.profile;
                        if (user != null && profile != null) {
                          context.read<RideProvider>().requestRide(
                            studentId: user.uid,
                            studentName: profile.name,
                            destination: dest,
                            collegeDomain: profile.collegeDomain,
                            zone: selectedZone,
                            requestedTime: selectedTime,
                          );
                        }
                      }
                    },
                    child: context.watch<RideProvider>().isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(AppStrings.findRider),
                  ),
                ),
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
    if (isRider) {
      switch (ride.status) {
        case RideStatus.accepted:
          statusMsg = 'Picking up ${ride.studentName}';
          break;
        case RideStatus.arrived:
          statusMsg = 'Waiting for ${ride.studentName}';
          break;
        case RideStatus.started:
          statusMsg = 'Driving to ${ride.destination}';
          break;
        default:
          statusMsg = 'Active Job';
      }
    } else {
      switch (ride.status) {
        case RideStatus.searching:
          statusMsg = 'Searching for nearby riders...';
          break;
        case RideStatus.requested:
          statusMsg = 'Waiting for rider to accept...'; // Hide rider name
          break;
        case RideStatus.accepted:
          statusMsg = 'Ride Accepted! ${ride.riderName} is coming.';
          break;
        case RideStatus.no_match:
          statusMsg = 'No riders available';
          break;
        default:
          statusMsg = 'Ride in progress';
      }
    }

    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ride.status == RideStatus.searching)
                const CircularProgressIndicator()
              else if (ride.status == RideStatus.no_match)
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                )
              else
                const Icon(
                  Icons.directions_car,
                  size: 48,
                  color: AppColors.primary,
                ),

              const SizedBox(height: 16),
              Text(
                statusMsg,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isRider)
                Text(
                  'Passenger: ${ride.studentName}',
                  style: const TextStyle(fontSize: 16),
                ),

              const SizedBox(height: 8),
              Text(
                'Destination: ${ride.destination}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // No Match Message and Retry
              if (!isRider && ride.status == RideStatus.no_match) ...[
                const Text(
                  'We couldn\'t find any available riders in your zone at this time.',
                  style: TextStyle(color: AppColors.textSecondary),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    rideProvider.cancelRide(
                      ride,
                      'No riders available - retrying',
                      context.read<AuthProvider>().user?.uid ?? '',
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],

              // Actions
              if (!isRider &&
                  (ride.status == RideStatus.searching ||
                      ride.status == RideStatus.requested))
                OutlinedButton(
                  onPressed: () =>
                      _showCancellationDialog(context, ride, false),
                  child: const Text('Cancel Request'),
                ),

              if (isRider && ride.status == RideStatus.accepted)
                ElevatedButton(
                  onPressed: () => rideProvider.completeRide(
                    ride,
                  ), // Should mark picked up/started first really, but for MVP Complete is OK or we skip steps.
                  // Let's just have "Complete Ride" for MVP Phase 1 simplicity
                  child: const Text('Complete Ride'),
                ),
            ],
          ),
        ),
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
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final req = requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(req.studentName),
              subtitle: Text('To: ${req.destination}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.error),
                    onPressed: () => context.read<RideProvider>().skipRide(req),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppColors.success),
                    onPressed: () =>
                        context.read<RideProvider>().acceptRide(req),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAvailable ? Icons.wifi_tethering : Icons.wifi_tethering_off,
            size: 80,
            color: isAvailable ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(height: 24),
          Text(
            isAvailable ? AppStrings.online : AppStrings.offline,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 16),
          if (isAvailable)
            const Text(
              'Waiting for ride requests...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Accepting Rides'),
            value: isAvailable,
            onChanged: (val) {
              _toggleMode(val, provider.profile!.id, provider);
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 48),
          ),
        ],
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
