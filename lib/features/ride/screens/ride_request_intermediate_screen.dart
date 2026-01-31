import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../../core/constants/app_colors.dart';
import 'quick_ride_request_screen.dart';

class RideRequestIntermediateScreen extends StatelessWidget {
  const RideRequestIntermediateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    developer.log('\n🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢', name: 'IntermediateScreen');
    developer.log('🟢 INTERMEDIATE SCREEN BUILD CALLED', name: 'IntermediateScreen');
    developer.log('🟢 This is the "Where to?" screen', name: 'IntermediateScreen');
    developer.log('🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢\n', name: 'IntermediateScreen');
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                'Where to?',
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
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    developer.log('\n🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵', name: 'IntermediateScreen');
                    developer.log('🔵 REQUEST RIDE BUTTON CLICKED', name: 'IntermediateScreen');
                    developer.log('🔵 Navigating to QuickRideRequestScreen...', name: 'IntermediateScreen');
                    developer.log('🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵🔵\n', name: 'IntermediateScreen');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuickRideRequestScreen(),
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
                    'Request Ride',
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
