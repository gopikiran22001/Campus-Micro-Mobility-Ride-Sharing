import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_point.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/ride/models/ride_model.dart';

class RideMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const int maxRadiusMeters = 5000;
  static const int routeProximityThresholdMeters = 500;
  static const int riderResponseTimeoutSeconds = 120;
  static const int totalMatchingTimeoutSeconds = 360;
  
  static const double weightEta = 0.4;
  static const double weightDistance = 0.3;
  static const double weightFairness = 0.3;

  Future<List<UserProfile>> findEligibleRiders({
    required String collegeDomain,
    required LocationPoint studentLocation,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .where('collegeDomain', isEqualTo: collegeDomain)
        .where('isRiderMode', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .get();

    final riders = snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data()))
        .where((rider) => 
            rider.activeRoute != null &&
            rider.vehicleType != VehicleType.none &&
            (rider.vehicleType == VehicleType.bike || 
             (rider.availableSeats != null && rider.availableSeats! > 0)))
        .toList();

    return riders;
  }

  bool isStudentOnRiderRoute({
    required LocationPoint studentLocation,
    required RiderRoute riderRoute,
  }) {
    final polyline = _decodePolyline(riderRoute.encodedPolyline);
    
    for (final routePoint in polyline) {
      final distance = _calculateDistance(
        studentLocation.latitude,
        studentLocation.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      
      if (distance <= routeProximityThresholdMeters) {
        return true;
      }
    }
    
    return false;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  Future<List<RiderMatch>> rankRiders({
    required List<UserProfile> eligibleRiders,
    required LocationPoint studentLocation,
  }) async {
    final matches = <RiderMatch>[];

    for (final rider in eligibleRiders) {
      final distance = _calculateDistance(
        studentLocation.latitude,
        studentLocation.longitude,
        rider.activeRoute!.startPoint.latitude,
        rider.activeRoute!.startPoint.longitude,
      );

      if (distance > maxRadiusMeters) {
        continue;
      }

      final eta = _estimateEta(distance);
      final fairnessScore = _calculateFairnessScore(rider);
      final totalScore = _calculateTotalScore(
        eta: eta,
        distance: distance,
        fairnessScore: fairnessScore,
      );

      matches.add(RiderMatch(
        rider: rider,
        distance: distance,
        eta: eta,
        fairnessScore: fairnessScore,
        totalScore: totalScore,
      ));
    }

    matches.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    return matches;
  }

  int _estimateEta(double distanceMeters) {
    const double averageSpeedMps = 8.33;
    final baseEta = (distanceMeters / averageSpeedMps).round();
    final trafficFactor = 1.2;
    return (baseEta * trafficFactor).round();
  }

  double _calculateFairnessScore(UserProfile rider) {
    final now = DateTime.now();
    final lastRideTime = rider.lastRideCompletedAt ?? now.subtract(const Duration(days: 365));
    final hoursSinceLastRide = now.difference(lastRideTime).inHours;
    return min(hoursSinceLastRide / 24.0, 1.0);
  }

  double _calculateTotalScore({
    required int eta,
    required double distance,
    required double fairnessScore,
  }) {
    final normalizedEta = min(eta / 600.0, 1.0);
    final normalizedDistance = min(distance / maxRadiusMeters, 1.0);
    final normalizedFairness = 1.0 - fairnessScore;

    return (normalizedEta * weightEta) +
           (normalizedDistance * weightDistance) +
           (normalizedFairness * weightFairness);
  }

  Future<bool> assignRiderToRide({
    required String rideId,
    required String riderId,
  }) async {
    try {
      final batch = _firestore.batch();

      batch.update(
        _firestore.collection('rides').doc(rideId),
        {
          'riderId': riderId,
          'status': RideStatus.requested.name,
          'assignedAt': FieldValue.serverTimestamp(),
        },
      );

      batch.update(
        _firestore.collection('users').doc(riderId),
        {
          'isAvailable': false,
          'lastRideAssignedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> releaseRider(String riderId) async {
    await _firestore.collection('users').doc(riderId).update({
      'isAvailable': true,
    });
  }

  Future<MatchingResult> matchRideWithTimeout({
    required Ride ride,
    required LocationPoint studentLocation,
  }) async {
    final startTime = DateTime.now();
    
    final eligibleRiders = await findEligibleRiders(
      collegeDomain: ride.collegeDomain,
      studentLocation: studentLocation,
    );

    final routeCompatibleRiders = eligibleRiders.where((rider) {
      return isStudentOnRiderRoute(
        studentLocation: studentLocation,
        riderRoute: rider.activeRoute!,
      );
    }).toList();

    if (routeCompatibleRiders.isEmpty) {
      return MatchingResult(
        success: false,
        message: 'No riders found on compatible routes',
      );
    }

    final rankedMatches = await rankRiders(
      eligibleRiders: routeCompatibleRiders,
      studentLocation: studentLocation,
    );

    if (rankedMatches.isEmpty) {
      return MatchingResult(
        success: false,
        message: 'No riders within acceptable range',
      );
    }

    for (final match in rankedMatches) {
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      if (elapsed >= totalMatchingTimeoutSeconds) {
        return MatchingResult(
          success: false,
          message: 'Matching timeout exceeded',
        );
      }

      final assigned = await assignRiderToRide(
        rideId: ride.id,
        riderId: match.rider.id,
      );

      if (!assigned) {
        continue;
      }

      final accepted = await _waitForRiderResponse(
        rideId: ride.id,
        riderId: match.rider.id,
      );

      if (accepted) {
        return MatchingResult(
          success: true,
          riderId: match.rider.id,
          riderName: match.rider.name,
          eta: match.eta,
        );
      }

      await releaseRider(match.rider.id);
    }

    return MatchingResult(
      success: false,
      message: 'All riders declined or timed out',
    );
  }

  Future<bool> _waitForRiderResponse({
    required String rideId,
    required String riderId,
  }) async {
    final completer = Completer<bool>();
    StreamSubscription? subscription;

    final timeout = Timer(
      Duration(seconds: riderResponseTimeoutSeconds),
      () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(false);
        }
      },
    );

    subscription = _firestore
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || completer.isCompleted) {
        return;
      }

      final data = snapshot.data();
      if (data == null) return;

      final status = data['status'] as String?;
      
      if (status == RideStatus.accepted.name) {
        timeout.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      } else if (status == RideStatus.cancelled.name) {
        timeout.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });

    return completer.future;
  }
}

class RiderMatch {
  final UserProfile rider;
  final double distance;
  final int eta;
  final double fairnessScore;
  final double totalScore;

  RiderMatch({
    required this.rider,
    required this.distance,
    required this.eta,
    required this.fairnessScore,
    required this.totalScore,
  });
}

class MatchingResult {
  final bool success;
  final String? riderId;
  final String? riderName;
  final int? eta;
  final String? message;

  MatchingResult({
    required this.success,
    this.riderId,
    this.riderName,
    this.eta,
    this.message,
  });
}
