import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/college_domains.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deptController = TextEditingController();
  final _yearController = TextEditingController();

  bool _hasVehicle = false;
  VehicleType _vehicleType = VehicleType.none;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = context.read<AuthProvider>().user;
      if (user == null) {
        // Should not happen if guided correctly
        setState(() => _isLoading = false);
        return;
      }

      final collegeName =
          CollegeDomains.getCollegeName(user.email ?? '') ?? 'Unknown College';

      final profile = UserProfile(
        id: user.uid,
        email: user.email ?? '',
        name: _nameController.text.trim(),
        department: _deptController.text.trim(),
        year: _yearController.text.trim(),
        collegeName: collegeName,
        collegeDomain: user.email!.split('@').last,
        hasVehicle: _hasVehicle,
        vehicleType: _hasVehicle ? _vehicleType : VehicleType.none,
        isRiderMode: false,
        isAvailable: false,
      );

      try {
        await context.read<ProfileProvider>().createOrUpdateProfile(profile);
        if (mounted) {
          // Success, go to Home
          context.go('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete your profile',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Personal Info
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.nameLabel,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(
                  labelText: AppStrings.deptLabel,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Department is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(
                  labelText: AppStrings.yearLabel,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Year is required' : null,
              ),
              const SizedBox(height: 32),

              // Vehicle Info
              const Text(
                AppStrings.vehicleLabel,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('I have a vehicle'),
                subtitle: const Text('You can offer rides to others'),
                value: _hasVehicle,
                onChanged: (val) {
                  setState(() {
                    _hasVehicle = val;
                    if (!val) {
                      _vehicleType = VehicleType.none;
                    } else if (_vehicleType == VehicleType.none) {
                      _vehicleType = VehicleType.bike; // Default
                    }
                  });
                },
              ),

              if (_hasVehicle) ...[
                const SizedBox(height: 16),
                const Text('Vehicle Type'),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<VehicleType>(
                        title: const Text(AppStrings.vehicleBike),
                        value: VehicleType.bike,
                        groupValue: _vehicleType,
                        onChanged: (val) => setState(() => _vehicleType = val!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<VehicleType>(
                        title: const Text(AppStrings.vehicleScooter),
                        value: VehicleType.scooter,
                        groupValue: _vehicleType,
                        onChanged: (val) => setState(() => _vehicleType = val!),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSave,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(AppStrings.profileSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
