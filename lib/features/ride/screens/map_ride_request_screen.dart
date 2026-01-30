import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/location_point.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ride_provider.dart';
import '../models/ride_model.dart';
import 'osm_location_picker_screen.dart';

class MapRideRequestScreen extends StatefulWidget {
  const MapRideRequestScreen({super.key});

  @override
  State<MapRideRequestScreen> createState() => _MapRideRequestScreenState();
}

class _MapRideRequestScreenState extends State<MapRideRequestScreen> {
  LocationPoint? _pickupPoint;
  LocationPoint? _destinationPoint;
  String _selectedZone = 'Central';
  RideTime _selectedTime = RideTime.now;
  VehicleType _selectedVehicleType = VehicleType.bike;
  int _requestedSeats = 1;

  Future<void> _selectPickup() async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          title: 'Select Pickup Location',
          initialLocation: _pickupPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() => _pickupPoint = result);
    }
  }

  Future<void> _selectDestination() async {
    final result = await Navigator.push<LocationPoint>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          title: 'Select Destination',
          initialLocation: _destinationPoint,
        ),
      ),
    );

    if (result != null) {
      setState(() => _destinationPoint = result);
    }
  }

  void _requestRide() {
    if (_pickupPoint == null || _destinationPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both pickup and destination'),
        ),
      );
      return;
    }

    if (_pickupPoint == _destinationPoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup and destination must be different'),
        ),
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    final profile = context.read<ProfileProvider>().profile;

    if (user != null && profile != null) {
      context.read<RideProvider>().requestRide(
            studentId: user.uid,
            studentName: profile.name,
            destination: _destinationPoint!.displayName,
            collegeDomain: profile.collegeDomain,
            zone: _selectedZone,
            requestedTime: _selectedTime,
            vehicleType: _selectedVehicleType,
            requestedSeats: _requestedSeats,
            pickupPoint: _pickupPoint,
            destinationPoint: _destinationPoint,
          );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ride'),
      ),
      body: Container(
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
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.trip_origin,
                          color: Colors.green,
                        ),
                        title: Text(
                          _pickupPoint?.displayName ?? 'Select Pickup Location',
                          style: TextStyle(
                            color: _pickupPoint == null
                                ? AppColors.textSecondary
                                : Colors.white,
                          ),
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _selectPickup,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        title: Text(
                          _destinationPoint?.displayName ??
                              'Select Destination',
                          style: TextStyle(
                            color: _destinationPoint == null
                                ? AppColors.textSecondary
                                : Colors.white,
                          ),
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: _selectDestination,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedZone,
                        decoration: InputDecoration(
                          labelText: 'Campus Zone',
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
                            setState(() => _selectedZone = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<RideTime>(
                        value: _selectedTime,
                        decoration: InputDecoration(
                          labelText: 'When?',
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
                            setState(() => _selectedTime = value);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<VehicleType>(
                        value: _selectedVehicleType,
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
                              _selectedVehicleType = value;
                              if (value == VehicleType.bike) {
                                _requestedSeats = 1;
                              }
                            });
                          }
                        },
                      ),
                      if (_selectedVehicleType == VehicleType.car) ...[ 
                        const SizedBox(height: 20),
                        DropdownButtonFormField<int>(
                          value: _requestedSeats,
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
                              setState(() => _requestedSeats = value);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _requestRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.search, size: 24),
                  label: const Text(
                    'Find Rider',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
