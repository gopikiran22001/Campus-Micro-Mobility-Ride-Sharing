enum VehicleType { none, scooter, bike }

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String department;
  final String year; // e.g., "Freshman", "2026"
  final String collegeName;
  final String collegeDomain;
  final bool hasVehicle;
  final VehicleType vehicleType;
  final bool isRiderMode; // Toggle for "Accepting Rides" (Availability)
  final bool isAvailable; // Real-time availability status
  final int reputationScore; // Fair Matching
  final DateTime? lastRideCompletedAt; // Riders Cooldown Logic
  final String zone; // Zone for proximity matching

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.department,
    required this.year,
    required this.collegeName,
    required this.collegeDomain,
    required this.hasVehicle,
    this.vehicleType = VehicleType.none,
    this.isRiderMode = false,
    this.isAvailable = false,
    this.reputationScore = 100,
    this.lastRideCompletedAt,
    this.zone = 'Central',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'department': department,
      'year': year,
      'collegeName': collegeName,
      'collegeDomain': collegeDomain,
      'hasVehicle': hasVehicle,
      'vehicleType': vehicleType.name,
      'isRiderMode': isRiderMode,
      'isAvailable': isAvailable,
      'reputationScore': reputationScore,
      'lastRideCompletedAt': lastRideCompletedAt?.toIso8601String(),
      'zone': zone,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      collegeName: map['collegeName'] ?? '',
      collegeDomain: map['collegeDomain'] ?? '',
      hasVehicle: map['hasVehicle'] ?? false,
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
        orElse: () => VehicleType.none,
      ),
      isRiderMode: map['isRiderMode'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      reputationScore: map['reputationScore'] ?? 100, // Default 100
      lastRideCompletedAt: map['lastRideCompletedAt'] != null
          ? DateTime.parse(map['lastRideCompletedAt'])
          : null,
      zone: map['zone'] ?? 'Central',
    );
  }

  UserProfile copyWith({
    String? name,
    String? department,
    String? year,
    String? collegeName,
    String? collegeDomain,
    bool? hasVehicle,
    VehicleType? vehicleType,
    bool? isRiderMode,
    bool? isAvailable,
    int? reputationScore,
    DateTime? lastRideCompletedAt,
    String? zone,
  }) {
    return UserProfile(
      id: id,
      email: email,
      name: name ?? this.name,
      department: department ?? this.department,
      year: year ?? this.year,
      collegeName: collegeName ?? this.collegeName,
      collegeDomain: collegeDomain ?? this.collegeDomain,
      hasVehicle: hasVehicle ?? this.hasVehicle,
      vehicleType: vehicleType ?? this.vehicleType,
      isRiderMode: isRiderMode ?? this.isRiderMode,
      isAvailable: isAvailable ?? this.isAvailable,
      reputationScore: reputationScore ?? this.reputationScore,
      lastRideCompletedAt: lastRideCompletedAt ?? this.lastRideCompletedAt,
      zone: zone ?? this.zone,
    );
  }
}
