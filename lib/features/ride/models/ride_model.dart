import '../../profile/models/user_profile.dart';
import '../../../core/models/location_point.dart';

enum RideStatus {
  searching, // Looking for riders
  requested, // Waiting for specific rider response
  accepted, // Rider accepted
  arrived, // Rider arrived (optional)
  started, // Ride in progress
  completed, // Done
  cancelled, // Cancelled by either
  no_match, // No riders found after timeout
}

enum RideTime {
  now, // Immediate
  soon, // Next 30 minutes
}

class Ride {
  final String id;
  final String studentId;
  final String studentName;
  final String? riderId;
  final String? riderName;
  final String origin;
  final String destination;
  final LocationPoint? pickupPoint;
  final LocationPoint? destinationPoint;
  final String zone;
  final VehicleType vehicleType;
  final int requestedSeats;
  final RideStatus status;
  final RideTime requestedTime;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? matchingStartedAt;
  final DateTime? requestSentAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final List<String> declinedRiderIds;

  Ride({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.riderId,
    this.riderName,
    required this.origin,
    required this.destination,
    this.pickupPoint,
    this.destinationPoint,
    required this.zone,
    required this.vehicleType,
    this.requestedSeats = 1,
    this.status = RideStatus.searching,
    this.requestedTime = RideTime.now,
    required this.createdAt,
    this.completedAt,
    this.matchingStartedAt,
    this.requestSentAt,
    this.cancellationReason,
    this.cancelledBy,
    this.declinedRiderIds = const [],
  })  : assert(
          vehicleType != VehicleType.bike || requestedSeats == 1,
          'Bike rides must request exactly 1 seat',
        ),
        assert(
          requestedSeats >= 1,
          'Must request at least 1 seat',
        );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'riderId': riderId,
      'riderName': riderName,
      'origin': origin,
      'destination': destination,
      'pickupPoint': pickupPoint?.toMap(),
      'destinationPoint': destinationPoint?.toMap(),
      'zone': zone,
      'vehicleType': vehicleType.name,
      'requestedSeats': requestedSeats,
      'status': status.name,
      'requestedTime': requestedTime.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'matchingStartedAt': matchingStartedAt?.toIso8601String(),
      'requestSentAt': requestSentAt?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
      'declinedRiderIds': declinedRiderIds,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      riderId: map['riderId'],
      riderName: map['riderName'],
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      pickupPoint: map['pickupPoint'] != null
          ? LocationPoint.fromMap(map['pickupPoint'])
          : null,
      destinationPoint: map['destinationPoint'] != null
          ? LocationPoint.fromMap(map['destinationPoint'])
          : null,
      zone: map['zone'] ?? 'Central',
      vehicleType: VehicleType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
        orElse: () => VehicleType.bike,
      ),
      requestedSeats: map['requestedSeats'] ?? 1,
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.searching,
      ),
      requestedTime: RideTime.values.firstWhere(
        (e) => e.name == map['requestedTime'],
        orElse: () => RideTime.now,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      matchingStartedAt: map['matchingStartedAt'] != null
          ? DateTime.parse(map['matchingStartedAt'])
          : null,
      requestSentAt: map['requestSentAt'] != null
          ? DateTime.parse(map['requestSentAt'])
          : null,
      cancellationReason: map['cancellationReason'],
      cancelledBy: map['cancelledBy'],
      declinedRiderIds: List<String>.from(map['declinedRiderIds'] ?? []),
    );
  }

  Ride copyWith({
    String? riderId,
    String? riderName,
    RideStatus? status,
    DateTime? completedAt,
    DateTime? matchingStartedAt,
    DateTime? requestSentAt,
    String? cancellationReason,
    String? cancelledBy,
    List<String>? declinedRiderIds,
  }) {
    return Ride(
      id: id,
      studentId: studentId,
      studentName: studentName,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      origin: origin,
      destination: destination,
      pickupPoint: pickupPoint,
      destinationPoint: destinationPoint,
      zone: zone,
      vehicleType: vehicleType,
      requestedSeats: requestedSeats,
      status: status ?? this.status,
      requestedTime: requestedTime,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      matchingStartedAt: matchingStartedAt ?? this.matchingStartedAt,
      requestSentAt: requestSentAt ?? this.requestSentAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      declinedRiderIds: declinedRiderIds ?? this.declinedRiderIds,
    );
  }
}
