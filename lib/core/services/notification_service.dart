import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// FCM Notification Service
/// Handles Firebase Cloud Messaging for ride notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('User granted provisional notification permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Store token for later use (optional)
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      // Update stored token
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (requires top-level function)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Save FCM token to user profile
  Future<void> saveTokenToDatabase(String userId) async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');
    // Show local notification or update UI
  }

  /// Send notification to specific user (client-triggered)
  /// Note: For production, this should be server-side (requires Blaze plan)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken == null) {
        debugPrint('User $userId has no FCM token');
        return;
      }

      // Store notification in Firestore (client-triggered approach for Spark plan)
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      debugPrint('Notification queued for user $userId');

      // NOTE: Actual sending requires Cloud Function (Blaze plan)
      // For Spark plan, this creates a notification record only
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Ride-specific notification helpers
  Future<void> notifyRiderOfNewRequest({
    required String riderId,
    required String studentName,
    required String destination,
    required String rideId,
  }) async {
    await sendNotificationToUser(
      userId: riderId,
      title: 'New Ride Request',
      body: '$studentName needs a ride to $destination',
      data: {'type': 'ride_request', 'rideId': rideId},
    );
  }

  Future<void> notifyStudentOfAcceptance({
    required String studentId,
    required String riderName,
    required String rideId,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Ride Accepted!',
      body: '$riderName has accepted your ride request',
      data: {'type': 'ride_accepted', 'rideId': rideId},
    );
  }

  Future<void> notifyStudentOfNoMatch({required String studentId}) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'No Riders Available',
      body: 'We couldn\'t find a rider for your request. Please try again.',
      data: {'type': 'no_match'},
    );
  }

  Future<void> notifyStudentOfCancellation({
    required String studentId,
    required String riderName,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Ride Cancelled',
      body: '$riderName has cancelled the ride',
      data: {'type': 'ride_cancelled'},
    );
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.notification?.title}');
}
