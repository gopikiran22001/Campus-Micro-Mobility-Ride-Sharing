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
    try {
      print('\n🔍 SEARCHING FOR RIDERS:');
      print('College Domain: $collegeDomain');
      
      // First, get all users in the college domain
      final allUsersSnapshot = await _firestore
          .collection('users')
          .where('collegeDomain', isEqualTo: collegeDomain)
          .get();
      
      print('Total users in domain: ${allUsersSnapshot.docs.length}');
      
      // Then filter for riders
      final riderSnapshot = await _firestore
          .collection('users')
          .where('collegeDomain', isEqualTo: collegeDomain)
          .where('isRiderMode', isEqualTo: true)
          .get();
      
      print('Users in rider mode: ${riderSnapshot.docs.length}');
      
      // Finally filter for available riders
      final availableSnapshot = await _firestore
          .collection('users')
          .where('collegeDomain', isEqualTo: collegeDomain)
          .where('isRiderMode', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      print('Available riders: ${availableSnapshot.docs.length}');

      final riders = availableSnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              print('Processing rider doc: ${doc.id}');
              print('Data: $data');
              return UserProfile.fromMap(data);
            } catch (e) {
              print('❌ Error parsing rider profile ${doc.id}: $e');
              return null;
            }
          })
          .where((rider) => rider != null)
          .cast<UserProfile>()
          .toList();

      print('\n📊 RIDER ANALYSIS:');
      for (final rider in riders) {
        print('Rider: ${rider.name}');
        print('  - Vehicle: ${rider.vehicleType.name}');
        print('  - Available: ${rider.isAvailable}');
        print('  - Has Route: ${rider.activeRoute != null}');
        print('  - Available Seats: ${rider.availableSeats}');
        print('  - Has Vehicle: ${rider.hasVehicle}');
      }

      final eligibleRiders = riders.where((rider) {
        // Check basic requirements
        if (rider.vehicleType == VehicleType.none) {
          print('❌ ${rider.name}: No vehicle type set');
          return false;
        }
        
        if (rider.activeRoute == null) {
          print('❌ ${rider.name}: No active route');
          return false;
        }
        
        // For cars, check available seats
        if (rider.vehicleType == VehicleType.car) {
          if (rider.availableSeats == null || rider.availableSeats! <= 0) {
            print('❌ ${rider.name}: No available seats (${rider.availableSeats})');
            return false;
          }
        }
        
        print('✅ ${rider.name}: Eligible');
        return true;
      }).toList();
      
      print('\n✅ Found ${eligibleRiders.length} eligible riders');
      return eligibleRiders;
    } catch (e) {
      print('❌ Error finding eligible riders: $e');
      return [];
    }
  }

  bool isStudentOnRiderRoute({
    required LocationPoint studentLocation,
    required RiderRoute riderRoute,
  }) {
    // Check if encoded polyline exists and is valid
    if (riderRoute.encodedPolyline.isEmpty) {
      // Fallback: check distance from start point
      final distanceFromStart = _calculateDistance(
        studentLocation.latitude,
        studentLocation.longitude,
        riderRoute.startPoint.latitude,
        riderRoute.startPoint.longitude,
      );
      return distanceFromStart <= maxRadiusMeters;
    }
    
    final polyline = _decodePolyline(riderRoute.encodedPolyline);
    
    // If polyline decode failed, fallback to start point check
    if (polyline.isEmpty) {
      final distanceFromStart = _calculateDistance(
        studentLocation.latitude,
        studentLocation.longitude,
        riderRoute.startPoint.latitude,
        riderRoute.startPoint.longitude,
      );
      return distanceFromStart <= maxRadiusMeters;
    }
    
    // Check proximity to any point on the route
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
    if (encoded.isEmpty) {
      print('Warning: Empty polyline string provided');
      return [];
    }
    
    try {
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
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < len);
        int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lat += dlat;

        shift = 0;
        result = 0;
        do {
          if (index >= len) break;
          b = encoded.codeUnitAt(index++) - 63;
          result |= (b & 0x1f) << shift;
          shift += 5;
        } while (b >= 0x20 && index < len);
        int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
        lng += dlng;

        points.add(LatLng(lat / 1E5, lng / 1E5));
      }
      
      print('Decoded ${points.length} points from polyline');
      return points;
    } catch (e) {
      print('Error decoding polyline: $e');
      return [];
    }
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
    print('\n=== RIDE MATCHING STARTED ===');
    print('Student: ${ride.studentName}');
    print('College Domain: ${ride.collegeDomain}');
    print('Student Location: ${studentLocation.latitude}, ${studentLocation.longitude}');
    
    final eligibleRiders = await findEligibleRiders(
      collegeDomain: ride.collegeDomain,
      studentLocation: studentLocation,
    );

    print('Found ${eligibleRiders.length} eligible riders');
    
    if (eligibleRiders.isEmpty) {
      return MatchingResult(
        success: false,
        message: 'No eligible riders found in your college domain',
      );
    }

    final routeCompatibleRiders = eligibleRiders.where((rider) {
      final isCompatible = isStudentOnRiderRoute(
        studentLocation: studentLocation,
        riderRoute: rider.activeRoute!,
      );
      print('Rider ${rider.name}: Route compatible = $isCompatible');
      return isCompatible;
    }).toList();

    print('Found ${routeCompatibleRiders.length} route-compatible riders');

    if (routeCompatibleRiders.isEmpty) {
      return MatchingResult(
        success: false,
        message: 'No riders found on compatible routes (within ${routeProximityThresholdMeters}m of your location)',
      );
    }

    final rankedMatches = await rankRiders(
      eligibleRiders: routeCompatibleRiders,
      studentLocation: studentLocation,
    );

    print('Ranked ${rankedMatches.length} matches');

    if (rankedMatches.isEmpty) {
      return MatchingResult(
        success: false,
        message: 'No riders within acceptable range (${maxRadiusMeters}m)',
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

      print('Trying to assign rider: ${match.rider.name}');
      final assigned = await assignRiderToRide(
        rideId: ride.id,
        riderId: match.rider.id,
      );

      if (!assigned) {
        print('Failed to assign rider: ${match.rider.name}');
        continue;
      }

      print('Waiting for rider response: ${match.rider.name}');
      final accepted = await _waitForRiderResponse(
        rideId: ride.id,
        riderId: match.rider.id,
      );

      if (accepted) {
        print('Rider accepted: ${match.rider.name}');
        return MatchingResult(
          success: true,
          riderId: match.rider.id,
          riderName: match.rider.name,
          eta: match.eta,
        );
      }

      print('Rider declined or timed out: ${match.rider.name}');
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
