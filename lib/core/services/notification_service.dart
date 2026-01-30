import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
}

/// FCM Notification Service
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
    } else {
      debugPrint('❌ Notification permission denied');
      return;
    }

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Ride Notifications',
      description: 'Notifications for ride requests and updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('📱 FCM Token: $token');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Save FCM token to user profile
  Future<void> saveTokenToDatabase(String userId) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM token saved for user: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.notification?.title}');
    
    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'CampusGo',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Ride Notifications',
      channelDescription: 'Notifications for ride requests and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    // Navigate to appropriate screen based on data
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
  }

  /// Send notification to specific user (client-triggered)
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
        debugPrint('⚠️ User $userId has no FCM token');
        return;
      }

      // Store notification in Firestore for Cloud Function to process
      await _firestore.collection('notifications').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'title': title,
        'body': body,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      debugPrint('✅ Notification queued for user $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
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
      title: 'New Ride Request 🚴',
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
      title: 'Ride Confirmed 🚲',
      body: 'Your ride has been accepted. The rider will arrive shortly.',
      data: {'type': 'ride_accepted', 'rideId': rideId},
    );
  }

  Future<void> notifyStudentOfRiderSkipped({
    required String studentId,
    required String rideId,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Searching for Another Rider',
      body: 'This rider skipped your request. Looking for the next available rider.',
      data: {'type': 'rider_skipped', 'rideId': rideId},
    );
  }

  Future<void> notifyStudentOfMatchingInProgress({
    required String studentId,
    required String rideId,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Finding You a Ride ⏳',
      body: 'We\'re checking nearby riders. Please hold on for a moment.',
      data: {'type': 'matching_in_progress', 'rideId': rideId},
    );
  }

  Future<void> notifyStudentOfNoMatch({required String studentId}) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'No Ride Available 🚫',
      body: 'No riders are available right now. Try again in a few minutes.',
      data: {'type': 'no_match'},
    );
  }

  Future<void> notifyStudentOfCancellation({
    required String studentId,
    required String riderName,
  }) async {
    await sendNotificationToUser(
      userId: studentId,
      title: 'Ride Cancelled 🚨',
      body: 'The ride has been cancelled. You can request a new ride anytime.',
      data: {'type': 'ride_cancelled'},
    );
  }

  Future<void> notifyRiderOfCancellation({
    required String riderId,
    required String studentName,
  }) async {
    await sendNotificationToUser(
      userId: riderId,
      title: 'Ride Cancelled 🚨',
      body: 'The ride has been cancelled. You can request a new ride anytime.',
      data: {'type': 'ride_cancelled'},
    );
  }

  Future<void> notifyRideStarted({
    required String userId,
    required String otherUserName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Ride Started 🚀',
      body: 'Your ride with $otherUserName has started. Have a safe journey!',
      data: {'type': 'ride_started'},
    );
  }

  Future<void> notifyRideCompleted({
    required String userId,
    required String otherUserName,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: 'Ride Completed 🎉',
      body: 'Your ride is complete. Thank you for using CampusGo!',
      data: {'type': 'ride_completed'},
    );
  }
}