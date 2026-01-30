import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/user_profile.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/osm_map_service.dart';
import '../../../core/models/location_point.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService = RideService();
  final ProfileService _profileService = ProfileService();
  final NotificationService _notificationService = NotificationService();
  final OsmMapService _mapService = OsmMapService();

  Ride? _activeRide;
  Ride? get activeRide => _activeRide;

  // For Rider Mode
  List<Ride> _incomingRequests = [];
  List<Ride> get incomingRequests => _incomingRequests;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Stream Subscriptions
  StreamSubscription<Ride?>? _activeRideSubscription;
  StreamSubscription<List<Ride>>? _incomingRequestsSubscription;

  @override
  void dispose() {
    _activeRideSubscription?.cancel();
    _incomingRequestsSubscription?.cancel();
    super.dispose();
  }

  void startListeningToActiveRide(String studentId) {
    _incomingRequestsSubscription?.cancel(); // Cancel other mode
    _activeRideSubscription?.cancel();
    _activeRideSubscription = _rideService
        .streamActiveRideForStudent(studentId)
        .listen((ride) {
          _activeRide = ride;
          notifyListeners();
        });
  }

  void startListeningToIncomingRequests(String riderId) {
    _incomingRequestsSubscription?.cancel();
    _activeRideSubscription?.cancel();

    // Listen for Requests
    _incomingRequestsSubscription = _rideService
        .streamIncomingRequestsForRider(riderId)
        .listen((rides) {
          _incomingRequests = rides;
          notifyListeners();
        });

    // Listen for Active Job
    _activeRideSubscription = _rideService
        .streamActiveRideForRider(riderId)
        .listen((ride) {
          _activeRide = ride;
          notifyListeners();
        });
  }

  void stopListening() {
    _activeRideSubscription?.cancel();
    _incomingRequestsSubscription?.cancel();
    _activeRide = null;
    _incomingRequests = [];
    notifyListeners();
  }

  // Student: Request a Ride
  Future<void> requestRide({
    required String studentId,
    required String studentName,
    required String destination,
    required String collegeDomain,
    required String zone,
    required RideTime requestedTime,
    required VehicleType vehicleType,
    int requestedSeats = 1,
    LocationPoint? pickupPoint,
    LocationPoint? destinationPoint,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newRide = Ride(
        id: const Uuid().v4(),
        studentId: studentId,
        studentName: studentName,
        origin: 'Current Location',
        destination: destination,
        zone: zone,
        vehicleType: vehicleType,
        requestedSeats: requestedSeats,
        requestedTime: requestedTime,
        status: RideStatus.searching,
        createdAt: DateTime.now(),
        matchingStartedAt: DateTime.now(),
        pickupPoint: pickupPoint,
        destinationPoint: destinationPoint,
      );

      await _rideService.createRide(newRide);
      _activeRide = newRide;

      await _findAndAssignRider(newRide, collegeDomain);
    } catch (e) {
      debugPrint('Error requesting ride: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _findAndAssignRider(Ride ride, String collegeDomain) async {
    const maxMatchingDuration = Duration(minutes: 6); // Total matching cap
    const riderResponseTimeout = Duration(minutes: 2); // Per-rider timeout

    final matchingStartTime = ride.matchingStartedAt ?? DateTime.now();

    while (true) {
      // Check total matching timeout
      final elapsedTime = DateTime.now().difference(matchingStartTime);
      if (elapsedTime >= maxMatchingDuration) {
        // Timeout exceeded - mark as no_match
        await _rideService.updateRideStatus(ride.id, RideStatus.no_match);
        _activeRide = ride.copyWith(status: RideStatus.no_match);
        notifyListeners();
        return;
      }

      // Get available riders in the same zone
      final riders = await _profileService.getAvailableRiders(
        collegeDomain,
        vehicleType: ride.vehicleType,
        requiredSeats: ride.requestedSeats,
      );

      // Filter by zone and declined list
      final candidates = riders
          .where(
            (r) => r.zone == ride.zone && !ride.declinedRiderIds.contains(r.id),
          )
          .toList();

      final routeFilteredCandidates = <UserProfile>[];
      if (ride.pickupPoint != null && ride.destinationPoint != null) {
        for (var rider in candidates) {
          if (rider.activeRoute != null) {
            final routePolyline = _mapService.decodePolyline(
              rider.activeRoute!.encodedPolyline,
            );
            final pickupNearRoute = _mapService.isPointNearRoute(
              ride.pickupPoint!,
              routePolyline,
              500,
            );
            final destinationNearRoute = _mapService.isPointNearRoute(
              ride.destinationPoint!,
              routePolyline,
              500,
            );
            if (pickupNearRoute && destinationNearRoute) {
              routeFilteredCandidates.add(rider);
            }
          }
        }
      }

      final finalCandidates = routeFilteredCandidates.isNotEmpty
          ? routeFilteredCandidates
          : candidates;

      if (finalCandidates.isEmpty) {
        // No riders available - mark as no_match
        await _rideService.updateRideStatus(ride.id, RideStatus.no_match);
        _activeRide = ride.copyWith(status: RideStatus.no_match);
        notifyListeners();

        // Notify student of no match
        await _notificationService.notifyStudentOfNoMatch(
          studentId: ride.studentId,
        );
        return;
      }

      // Pick first eligible rider (already sorted by fairness in service)
      final selectedRider = finalCandidates.first;

      // Update Ride with rider assignment and request timestamp
      await _rideService.assignRiderWithTimestamp(
        ride.id,
        selectedRider.id,
        selectedRider.name,
      );

      // Notify rider of new request
      await _notificationService.notifyRiderOfNewRequest(
        riderId: selectedRider.id,
        studentName: ride.studentName,
        destination: ride.destination,
        rideId: ride.id,
      );

      // Update local state
      _activeRide = ride.copyWith(
        riderId: selectedRider.id,
        riderName: selectedRider.name,
        status: RideStatus.requested,
        requestSentAt: DateTime.now(),
      );
      notifyListeners();

      // Wait for rider response (2 minutes)
      await Future.delayed(riderResponseTimeout);

      // Refresh ride state to check if accepted
      final updatedRide = await _rideService.getRideById(ride.id);
      if (updatedRide == null) return; // Ride was deleted/cancelled

      if (updatedRide.status == RideStatus.accepted) {
        // Rider accepted - success!
        return;
      } else if (updatedRide.status == RideStatus.cancelled) {
        // Student cancelled during wait
        return;
      } else if (updatedRide.status == RideStatus.requested) {
        // Rider didn't respond - add to declined list and retry
        final newDeclined = List<String>.from(ride.declinedRiderIds)
          ..add(selectedRider.id);

        // Notify student that rider skipped
        await _notificationService.notifyStudentOfRiderSkipped(
          studentId: ride.studentId,
          rideId: ride.id,
        );

        ride = ride.copyWith(
          status: RideStatus.searching,
          riderId: null,
          riderName: null,
          declinedRiderIds: newDeclined,
        );

        await _rideService.createRide(ride); // Update with new declined list
        _activeRide = ride;
        notifyListeners();

        // Continue loop to find next rider
      }
    }
  }

  // Student: Cancel
  Future<void> cancelRide(Ride ride, String reason, String userId) async {
    await _rideService.updateRideWithCancellation(
      ride.id,
      RideStatus.cancelled,
      reason,
      userId,
    );
    
    if (ride.riderId != null && ride.status == RideStatus.accepted) {
      await _notificationService.notifyRiderOfCancellation(
        riderId: ride.riderId!,
        studentName: ride.studentName,
      );
      
      if (ride.vehicleType == VehicleType.car) {
        await _profileService.restoreSeats(ride.riderId!, ride.requestedSeats);
      } else {
        await _profileService.updateAvailability(ride.riderId!, true);
      }
    }
    
    _activeRide = null;
    notifyListeners();
  }

  // Rider: Complete
  Future<void> completeRide(Ride ride) async {
    if (ride.riderId != null) {
      await _rideService.completeRide(ride.id, ride.riderId!);
      
      if (ride.vehicleType == VehicleType.car) {
        await _profileService.restoreSeats(ride.riderId!, ride.requestedSeats);
      } else {
        await _profileService.updateAvailability(ride.riderId!, true);
      }
      
      await _notificationService.notifyRideCompleted(
        userId: ride.studentId,
        otherUserName: ride.riderName ?? 'Rider',
      );
    } else {
      await _rideService.updateRideStatus(ride.id, RideStatus.completed);
    }
  }

  // Rider: Accept
  Future<void> acceptRide(Ride ride) async {
    if (ride.riderId == null) return;

    await _rideService.updateRideStatus(ride.id, RideStatus.accepted);

    if (ride.vehicleType == VehicleType.car) {
      await _profileService.deductSeats(ride.riderId!, ride.requestedSeats);
    } else {
      await _profileService.updateAvailability(ride.riderId!, false);
    }

    final rider = await _profileService.getUserProfile(ride.riderId!);
    if (rider != null) {
      await _notificationService.notifyStudentOfAcceptance(
        studentId: ride.studentId,
        riderName: rider.name,
        rideId: ride.id,
      );
    }
  }

  // Rider: Skip / Reject
  Future<void> skipRide(Ride ride) async {
    // Add to declined list
    final newDeclined = List<String>.from(ride.declinedRiderIds)
      ..add(ride.riderId!);

    // Reset riderId, set back to searching (so Student logic picks next)
    // Actually, simpler if Rider just updates status to searching + adds self to declined.
    // But working with Firestore arrays is safer.
    // For MVP we just update the DOC.

    // We ideally want the Student Provider to react and pick next.
    // BUT since Student might be idle, we might want the Rider to "release" it.
    // Let's have the Rider remove themselves.

    // However, if we follow strict "Student searches", the Student App is watching.
    // If Status goes back to searching (or specifically 'rejected_by_rider'), Student picks next.
    // Let's use a trigger approach: Rider update status to 'searching'.

    // We need to update declinedRiderIds in Firestore.
    // This requires a new method in Service, but for MVP let's assume update map.
    await _rideService.createRide(
      ride.copyWith(
        status: RideStatus.searching,
        riderId: null,
        declinedRiderIds: newDeclined,
      ),
    ); // Overwrite with new state
  }

  Future<void> setRiderRoute(String riderId, RiderRoute route) async {
    await _profileService.updateRiderRoute(riderId, route);
    notifyListeners();
  }

  Future<void> clearRiderRoute(String riderId) async {
    await _profileService.clearRiderRoute(riderId);
    notifyListeners();
  }
}
