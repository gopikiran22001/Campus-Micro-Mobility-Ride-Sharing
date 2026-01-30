import '../../../core/models/location_point.dart';

enum VehicleType { none, bike, car }

class RiderRoute {
  final LocationPoint startPoint;
  final LocationPoint endPoint;
  final String encodedPolyline;
  final int distanceMeters;
  final int durationSeconds;

  const RiderRoute({
    required this.startPoint,
    required this.endPoint,
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  Map<String, dynamic> toMap() {
    return {
      'startPoint': startPoint.toMap(),
      'endPoint': endPoint.toMap(),
      'encodedPolyline': encodedPolyline,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
    };
  }

  factory RiderRoute.fromMap(Map<String, dynamic> map) {
    return RiderRoute(
      startPoint: LocationPoint.fromMap(map['startPoint']),
      endPoint: LocationPoint.fromMap(map['endPoint']),
      encodedPolyline: map['encodedPolyline'] ?? '',
      distanceMeters: map['distanceMeters'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String department;
  final String year;
  final String collegeName;
  final String collegeDomain;
  final bool hasVehicle;
  final VehicleType vehicleType;
  final int? carSeats;
  final int? availableSeats;
  final bool isRiderMode;
  final bool isAvailable;
  final int reputationScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastRideCompletedAt;
  final String zone;
  final String? fcmToken;
  final RiderRoute? activeRoute;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.department,
    required this.year,
    required this.collegeName,
    required this.collegeDomain,
    required this.hasVehicle,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.vehicleType = VehicleType.none,
    this.carSeats,
    this.availableSeats,
    this.isRiderMode = false,
    this.isAvailable = false,
    this.reputationScore = 100,
    this.lastRideCompletedAt,
    this.zone = 'Central',
    this.fcmToken,
    this.activeRoute,
  })  : assert(
          vehicleType != VehicleType.car || (carSeats != null && carSeats >= 1),
          'Car must have at least 1 seat',
        ),
        assert(
          vehicleType != VehicleType.car ||
              (availableSeats != null && availableSeats <= (carSeats ?? 0)),
          'Available seats cannot exceed total car seats',
        ),
        assert(
          vehicleType == VehicleType.car || (carSeats == null && availableSeats == null),
          'Only cars can have seat counts',
        ),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

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
      'carSeats': carSeats,
      'availableSeats': availableSeats,
      'isRiderMode': isRiderMode,
      'isAvailable': isAvailable,
      'reputationScore': reputationScore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastRideCompletedAt': lastRideCompletedAt?.toIso8601String(),
      'zone': zone,
      'fcmToken': fcmToken,
      'activeRoute': activeRoute?.toMap(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final vehicleType = VehicleType.values.firstWhere(
      (e) => e.name == map['vehicleType'],
      orElse: () => VehicleType.none,
    );
    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      collegeName: map['collegeName'] ?? '',
      collegeDomain: map['collegeDomain'] ?? '',
      hasVehicle: map['hasVehicle'] ?? false,
      vehicleType: vehicleType,
      carSeats: vehicleType == VehicleType.car ? (map['carSeats'] ?? 4) : null,
      availableSeats: vehicleType == VehicleType.car ? (map['availableSeats'] ?? map['carSeats'] ?? 4) : null,
      isRiderMode: map['isRiderMode'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      reputationScore: map['reputationScore'] ?? 100,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      lastRideCompletedAt: map['lastRideCompletedAt'] != null
          ? DateTime.parse(map['lastRideCompletedAt'])
          : null,
      zone: map['zone'] ?? 'Central',
      fcmToken: map['fcmToken'],
      activeRoute: map['activeRoute'] != null
          ? RiderRoute.fromMap(map['activeRoute'])
          : null,
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
    int? carSeats,
    int? availableSeats,
    bool? isRiderMode,
    bool? isAvailable,
    int? reputationScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastRideCompletedAt,
    String? zone,
    String? fcmToken,
    RiderRoute? activeRoute,
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
      carSeats: carSeats ?? this.carSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      isRiderMode: isRiderMode ?? this.isRiderMode,
      isAvailable: isAvailable ?? this.isAvailable,
      reputationScore: reputationScore ?? this.reputationScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastRideCompletedAt: lastRideCompletedAt ?? this.lastRideCompletedAt,
      zone: zone ?? this.zone,
      fcmToken: fcmToken ?? this.fcmToken,
      activeRoute: activeRoute ?? this.activeRoute,
    );
  }
}
