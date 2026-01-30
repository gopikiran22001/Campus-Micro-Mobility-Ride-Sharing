import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rides';

  Future<void> createRide(Ride ride) async {
    await _firestore.collection(_collection).doc(ride.id).set(ride.toMap());
  }

  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'status': status.name,
    });
  }

  Future<void> assignRider(
    String rideId,
    String riderId,
    String riderName,
  ) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'riderId': riderId,
      'riderName': riderName,
      'status': RideStatus.requested.name,
    });
  }

  Future<void> assignRiderWithTimestamp(
    String rideId,
    String riderId,
    String riderName,
  ) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'riderId': riderId,
      'riderName': riderName,
      'status': RideStatus.requested.name,
      'requestSentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Ride?> getRideById(String rideId) async {
    final doc = await _firestore.collection(_collection).doc(rideId).get();
    if (doc.exists && doc.data() != null) {
      return Ride.fromMap(doc.data()!);
    }
    return null;
  }

  Future<void> completeRide(String rideId, String riderId) async {
    final batch = _firestore.batch();

    // 1. Update Ride Status
    final rideRef = _firestore.collection(_collection).doc(rideId);
    batch.update(rideRef, {
      'status': RideStatus.completed.name,
      'completedAt': DateTime.now().toIso8601String(),
    });

    // 2. Update Rider's Last Completed Time (Cooldown)
    final riderRef = _firestore.collection('users').doc(riderId);
    batch.update(riderRef, {
      'lastRideCompletedAt': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<void> updateRideWithCancellation(
    String rideId,
    RideStatus status,
    String reason,
    String cancelledBy,
  ) async {
    await _firestore.collection(_collection).doc(rideId).update({
      'status': status.name,
      'cancellationReason': reason,
      'cancelledBy': cancelledBy,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<Ride?> streamActiveRideForStudent(String studentId) {
    return _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        // We want any ride that is NOT cancelled or completed (active)
        // Firestore limited OR queries... let's separate or just query last created?
        // For MVP, assume one active ride at a time.
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final ride = Ride.fromMap(snapshot.docs.first.data());
          if (ride.status == RideStatus.cancelled ||
              ride.status == RideStatus.completed) {
            return null; // Not active
          }
          return ride;
        });
  }

  Stream<List<Ride>> streamIncomingRequestsForRider(String riderId) {
    return _firestore
        .collection(_collection)
        .where('riderId', isEqualTo: riderId)
        .where('status', isEqualTo: RideStatus.requested.name)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ride.fromMap(doc.data())).toList(),
        );
  }

  Stream<Ride?> streamActiveRideForRider(String riderId) {
    return _firestore
        .collection(_collection)
        .where('riderId', isEqualTo: riderId)
        // active: accepted, arrived, started
        .where('status', whereIn: ['accepted', 'arrived', 'started'])
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Ride.fromMap(snapshot.docs.first.data());
        });
  }
}
