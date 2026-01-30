import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<void> createProfile(UserProfile profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.id)
        .set(profile.toMap());
  }

  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _firestore.collection(_collection).doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromMap(doc.data()!);
    }
    return null;
  }

  // Alias for getProfile (for consistency)
  Future<UserProfile?> getUserProfile(String userId) => getProfile(userId);

  Future<void> updateProfile(UserProfile profile) async {
    await _firestore
        .collection(_collection)
        .doc(profile.id)
        .update(profile.toMap());
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _firestore.collection(_collection).doc(userId).update({
      'isAvailable': isAvailable,
    });
  }

  Future<void> deductSeats(String userId, int seatsToDeduct) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_collection).doc(userId);
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('User profile not found');
      }
      
      final profile = UserProfile.fromMap(snapshot.data()!);
      
      if (profile.vehicleType != VehicleType.car) {
        throw Exception('Only cars can have seats deducted');
      }
      
      final currentAvailable = profile.availableSeats ?? 0;
      if (currentAvailable < seatsToDeduct) {
        throw Exception('Not enough available seats');
      }
      
      final newAvailable = currentAvailable - seatsToDeduct;
      transaction.update(docRef, {
        'availableSeats': newAvailable,
        'isAvailable': newAvailable > 0,
      });
    });
  }

  Future<void> restoreSeats(String userId, int seatsToRestore) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection(_collection).doc(userId);
      final snapshot = await transaction.get(docRef);
      
      if (!snapshot.exists) {
        throw Exception('User profile not found');
      }
      
      final profile = UserProfile.fromMap(snapshot.data()!);
      
      if (profile.vehicleType != VehicleType.car) {
        throw Exception('Only cars can have seats restored');
      }
      
      final currentAvailable = profile.availableSeats ?? 0;
      final totalSeats = profile.carSeats ?? 0;
      final newAvailable = (currentAvailable + seatsToRestore).clamp(0, totalSeats);
      
      transaction.update(docRef, {
        'availableSeats': newAvailable,
        'isAvailable': true,
      });
    });
  }

  // For ride matching: Find available riders nearby (simplified query for MVP)
  // In real app, use GeoFlutterFire. Here we just query available riders
  // We will assume "campus" is small enough or we filter by college domain in query.
  Future<List<UserProfile>> getAvailableRiders(
    String collegeDomain, {
    VehicleType? vehicleType,
    int? requiredSeats,
  }) async {
    Query query = _firestore
        .collection(_collection)
        .where('isRiderMode', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where('collegeDomain', isEqualTo: collegeDomain);

    if (vehicleType != null) {
      query = query.where('vehicleType', isEqualTo: vehicleType.name);
    }

    final snapshot = await query.get();
    final riders = snapshot.docs
        .map((doc) => UserProfile.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (requiredSeats != null && requiredSeats > 1) {
      riders.removeWhere((rider) =>
          rider.vehicleType != VehicleType.car ||
          (rider.availableSeats ?? 0) < requiredSeats);
    }

    riders.sort((a, b) {
      if (a.lastRideCompletedAt == null) return -1;
      if (b.lastRideCompletedAt == null) return 1;
      return a.lastRideCompletedAt!.compareTo(b.lastRideCompletedAt!);
    });

    return riders;
  }

  Future<void> updateRiderRoute(String userId, RiderRoute route) async {
    await _firestore.collection(_collection).doc(userId).update({
      'activeRoute': route.toMap(),
    });
  }

  Future<void> clearRiderRoute(String userId) async {
    await _firestore.collection(_collection).doc(userId).update({
      'activeRoute': null,
    });
  }
}
