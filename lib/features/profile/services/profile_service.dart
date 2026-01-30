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

  // For ride matching: Find available riders nearby (simplified query for MVP)
  // In real app, use GeoFlutterFire. Here we just query available riders
  // We will assume "campus" is small enough or we filter by college domain in query.
  Future<List<UserProfile>> getAvailableRiders(String collegeDomain) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('isRiderMode', isEqualTo: true)
        .where('isAvailable', isEqualTo: true)
        .where(
          'collegeDomain',
          isEqualTo: collegeDomain,
        ) // Strict Campus Isolation
        .get();

    return snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())).toList()
      // Sort by Last Completed Ride (Ascending) -> Oldest (longest idle) first
      ..sort((a, b) {
        if (a.lastRideCompletedAt == null) {
          return -1; // Never ridden -> Priority 1
        }
        if (b.lastRideCompletedAt == null) {
          return 1;
        }
        return a.lastRideCompletedAt!.compareTo(b.lastRideCompletedAt!);
      });
  }
}
