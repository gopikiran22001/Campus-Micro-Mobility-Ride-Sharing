import '../../../core/models/location_point.dart';

enum RideStatus {
  searching,
  requested,
  accepted,
  arrived,
  started,
  completed,
  cancelled,
  noMatch,
}

class Ride {
  final String id;
  final String studentId;
  final String studentName;
  final String? riderId;
  final String? riderName;
  final String origin;
  final String destination;
  final String collegeDomain;
  final LocationPoint pickupPoint;
  final LocationPoint destinationPoint;
  final RideStatus status;
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
    required this.collegeDomain,
    required this.pickupPoint,
    required this.destinationPoint,
    this.status = RideStatus.searching,
    required this.createdAt,
    this.completedAt,
    this.matchingStartedAt,
    this.requestSentAt,
    this.cancellationReason,
    this.cancelledBy,
    this.declinedRiderIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'riderId': riderId,
      'riderName': riderName,
      'origin': origin,
      'destination': destination,
      'collegeDomain': collegeDomain,
      'pickupPoint': pickupPoint.toMap(),
      'destinationPoint': destinationPoint.toMap(),
      'status': status.name,
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
      collegeDomain: map['collegeDomain'] ?? '',
      pickupPoint: LocationPoint.fromMap(map['pickupPoint']),
      destinationPoint: LocationPoint.fromMap(map['destinationPoint']),
      status: RideStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RideStatus.searching,
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
      collegeDomain: collegeDomain,
      pickupPoint: pickupPoint,
      destinationPoint: destinationPoint,
      status: status ?? this.status,
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
