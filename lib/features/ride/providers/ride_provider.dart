import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/user_profile.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/ride_matching_service.dart';
import '../../../core/models/location_point.dart';

class RideProvider extends ChangeNotifier {
  final RideService _rideService = RideService();
  final ProfileService _profileService = ProfileService();
  final NotificationService _notificationService = NotificationService();
  final RideMatchingService _matchingService = RideMatchingService();

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
    required LocationPoint pickupPoint,
    required LocationPoint destinationPoint,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newRide = Ride(
        id: const Uuid().v4(),
        studentId: studentId,
        studentName: studentName,
        origin: pickupPoint.displayName,
        destination: destination,
        collegeDomain: collegeDomain,
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
    try {
      print('\n🔍 Starting rider matching for ride: ${ride.id}');
      print('Student: ${ride.studentName}');
      print('Destination: ${ride.destination}');
      print('College Domain: $collegeDomain');
      print('Pickup Location: ${ride.pickupPoint.latitude}, ${ride.pickupPoint.longitude}');
      
      final result = await _matchingService.matchRideWithTimeout(
        ride: ride,
        studentLocation: ride.pickupPoint,
      );

      print('Matching result: Success=${result.success}, Message=${result.message}');
      
      if (result.success && result.riderId != null) {
        print('✅ Match found! Rider: ${result.riderName} (${result.riderId})');
        await _rideService.updateRideStatus(ride.id, RideStatus.accepted);
        _activeRide = ride.copyWith(
          status: RideStatus.accepted,
          riderId: result.riderId,
          riderName: result.riderName,
        );
        
        await _notificationService.notifyStudentOfAcceptance(
          studentId: ride.studentId,
          riderName: result.riderName ?? 'Rider',
          rideId: ride.id,
        );
      } else {
        print('❌ No match found: ${result.message}');
        await _rideService.updateRideStatus(ride.id, RideStatus.noMatch);
        _activeRide = ride.copyWith(status: RideStatus.noMatch);
        
        await _notificationService.notifyStudentOfNoMatch(
          studentId: ride.studentId,
        );
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error in matching: $e');
      await _rideService.updateRideStatus(ride.id, RideStatus.noMatch);
      _activeRide = ride.copyWith(status: RideStatus.noMatch);
      notifyListeners();
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
      
      await _profileService.updateAvailability(ride.riderId!, true);
    }
    
    _activeRide = null;
    notifyListeners();
  }

  // Rider: Complete
  Future<void> completeRide(Ride ride) async {
    if (ride.riderId != null) {
      await _rideService.completeRide(ride.id, ride.riderId!);
      
      await _profileService.updateAvailability(ride.riderId!, true);
      
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

    await _profileService.updateAvailability(ride.riderId!, false);

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
    final newDeclined = List<String>.from(ride.declinedRiderIds)
      ..add(ride.riderId!);

    await _rideService.createRide(
      ride.copyWith(
        status: RideStatus.searching,
        riderId: null,
        declinedRiderIds: newDeclined,
      ),
    );
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
