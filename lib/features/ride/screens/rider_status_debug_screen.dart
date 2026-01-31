import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../profile/models/user_profile.dart';

class RiderStatusDebugScreen extends StatefulWidget {
  const RiderStatusDebugScreen({super.key});

  @override
  State<RiderStatusDebugScreen> createState() => _RiderStatusDebugScreenState();
}

class _RiderStatusDebugScreenState extends State<RiderStatusDebugScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserProfile> _allRiders = [];
  bool _isLoading = true;
  String? _selectedDomain;
  List<String> _domains = [];

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final domains = snapshot.docs
          .map((doc) => doc.data()['collegeDomain'] as String?)
          .where((domain) => domain != null)
          .cast<String>()
          .toSet()
          .toList();
      
      setState(() {
        _domains = domains;
        if (domains.isNotEmpty) {
          _selectedDomain = domains.first;
          _loadRiders();
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRiders() async {
    if (_selectedDomain == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('collegeDomain', isEqualTo: _selectedDomain)
          .get();

      final riders = snapshot.docs
          .map((doc) {
            try {
              return UserProfile.fromMap(doc.data());
            } catch (e) {
              return null;
            }
          })
          .where((rider) => rider != null)
          .cast<UserProfile>()
          .toList();

      setState(() {
        _allRiders = riders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRiderMode(UserProfile rider) async {
    try {
      await _firestore.collection('users').doc(rider.id).update({
        'isRiderMode': !rider.isRiderMode,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _loadRiders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleAvailability(UserProfile rider) async {
    try {
      await _firestore.collection('users').doc(rider.id).update({
        'isAvailable': !rider.isAvailable,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _loadRiders();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final riders = _allRiders.where((r) => r.isRiderMode).toList();
    final availableRiders = riders.where((r) => r.isAvailable).toList();
    final eligibleRiders = availableRiders.where((r) => 
        r.activeRoute != null && 
        r.vehicleType != VehicleType.none &&
        (r.vehicleType == VehicleType.bike || 
         (r.availableSeats != null && r.availableSeats! > 0))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Status Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedDomain,
                        decoration: const InputDecoration(
                          labelText: 'College Domain',
                          border: OutlineInputBorder(),
                        ),
                        items: _domains.map((domain) {
                          return DropdownMenuItem(
                            value: domain,
                            child: Text(domain),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDomain = value);
                          _loadRiders();
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard('Total Users', _allRiders.length, Colors.blue),
                          _StatCard('Riders', riders.length, Colors.orange),
                          _StatCard('Available', availableRiders.length, Colors.green),
                          _StatCard('Eligible', eligibleRiders.length, AppColors.primary),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allRiders.length,
                    itemBuilder: (context, index) {
                      final rider = _allRiders[index];
                      final isEligible = rider.isRiderMode && 
                          rider.isAvailable && 
                          rider.activeRoute != null && 
                          rider.vehicleType != VehicleType.none &&
                          (rider.vehicleType == VehicleType.bike || 
                           (rider.availableSeats != null && rider.availableSeats! > 0));

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isEligible ? Colors.green : Colors.grey,
                            child: Text(rider.name[0]),
                          ),
                          title: Text(rider.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vehicle: ${rider.vehicleType.name}'),
                              Text('Seats: ${rider.availableSeats ?? 'N/A'}'),
                              Text('Route: ${rider.activeRoute != null ? 'Set' : 'None'}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: rider.isRiderMode,
                                onChanged: (_) => _toggleRiderMode(rider),
                                activeColor: AppColors.primary,
                              ),
                              Switch(
                                value: rider.isAvailable,
                                onChanged: rider.isRiderMode ? (_) => _toggleAvailability(rider) : null,
                                activeColor: Colors.green,
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard(this.title, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}