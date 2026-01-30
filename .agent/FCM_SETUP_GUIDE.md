# Firebase Cloud Messaging (FCM) Setup Guide

## ✅ What's Already Done

1. ✅ `firebase_messaging` dependency added to `pubspec.yaml`
2. ✅ `NotificationService` created with full FCM integration
3. ✅ FCM initialized in `main.dart`
4. ✅ Notification triggers added to ride lifecycle:
   - New ride request → Notifies rider
   - Ride accepted → Notifies student
   - No match found → Notifies student
5. ✅ Token management implemented
6. ✅ Foreground and background message handlers

---

## ⚠️ Platform-Specific Setup Required

### **Android Setup**

#### 1. Update `android/app/build.gradle`

Add the following inside the `android` block:

```gradle
android {
    // ... existing config ...
    
    defaultConfig {
        // ... existing config ...
        minSdkVersion 21  // FCM requires minimum SDK 21
    }
}
```

#### 2. Verify `google-services.json`

Ensure `android/app/google-services.json` exists and is up-to-date.

If missing:
1. Go to Firebase Console → Project Settings
2. Download `google-services.json`
3. Place in `android/app/` directory

#### 3. Update `AndroidManifest.xml`

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
    <application>
        <!-- ... existing config ... -->
        
        <!-- FCM Notification Icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        
        <!-- FCM Notification Color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
    
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
</manifest>
```

#### 4. Create Notification Icon

Create `android/app/src/main/res/drawable/ic_notification.xml`:

```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24"
    android:tint="?attr/colorControlNormal">
    <path
        android:fillColor="@android:color/white"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.89,2 2,2zM18,16v-5c0,-3.07 -1.64,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.63,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

---

### **iOS Setup**

#### 1. Update `ios/Runner/Info.plist`

Add notification permissions:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

#### 2. Enable Push Notifications in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to "Signing & Capabilities"
4. Click "+ Capability"
5. Add "Push Notifications"
6. Add "Background Modes" and check "Remote notifications"

#### 3. Upload APNs Key to Firebase

1. Go to [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Create new Key with APNs enabled
3. Download `.p8` file
4. Go to Firebase Console → Project Settings → Cloud Messaging
5. Upload APNs key with Team ID and Key ID

#### 4. Verify `GoogleService-Info.plist`

Ensure `ios/Runner/GoogleService-Info.plist` exists.

If missing:
1. Firebase Console → Project Settings → iOS app
2. Download `GoogleService-Info.plist`
3. Drag into Xcode Runner folder

---

## 🔥 Server-Side Notification Sending (Blaze Plan Required)

### Current Implementation (Spark Plan Compatible)

The current implementation **queues notifications** in Firestore but doesn't actually send them. This is because:

- **Spark Plan**: Cannot use Cloud Functions
- **Client-Side**: Cannot directly call FCM API (requires server key)

### Upgrade to Blaze Plan for Full Functionality

Create `functions/index.js`:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Send notification when queued
exports.sendQueuedNotification = functions.firestore
    .document('notifications/{notificationId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        
        if (data.sent) return; // Already sent
        
        const message = {
            notification: {
                title: data.title,
                body: data.body,
            },
            data: data.data || {},
            token: data.fcmToken,
        };
        
        try {
            await admin.messaging().send(message);
            await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
            console.log('Notification sent successfully');
        } catch (error) {
            console.error('Error sending notification:', error);
            await snap.ref.update({ error: error.message });
        }
    });
```

Deploy:
```bash
firebase deploy --only functions
```

---

## 🧪 Testing Notifications

### Test on Physical Device

1. **Build and run on physical device** (emulators may not support FCM)

```bash
flutter run --release
```

2. **Check FCM token in logs:**

Look for: `FCM Token: <your-token>`

3. **Send test notification from Firebase Console:**

- Firebase Console → Cloud Messaging → Send test message
- Paste FCM token
- Send

### Test Ride Notifications

1. **Student requests ride** → Rider should receive notification
2. **Rider accepts** → Student should receive notification
3. **No riders available** → Student should receive "No match" notification

---

## 📱 Notification Permissions

### Request Permission (Already Implemented)

The app automatically requests notification permission on startup.

### Handle Permission Denial

If user denies permission:
- Notifications won't work
- App will still function normally
- User can enable in device settings later

---

## 🔍 Debugging

### Check if FCM is initialized:

```dart
// In main.dart, you should see:
// "User granted notification permission" or
// "User declined notification permission"
```

### Verify token is saved:

Check Firestore `users` collection → user document → `fcmToken` field

### Test foreground messages:

When app is open, check logs for:
```
Foreground message received: <title>
```

### Test background messages:

When app is in background, notification should appear in system tray.

---

## 🚨 Common Issues

### 1. "MissingPluginException"
**Solution:** Run `flutter clean && flutter pub get`

### 2. Notifications not received on iOS
**Solution:** 
- Verify APNs key is uploaded
- Check device has internet
- Ensure app has notification permission

### 3. Notifications not received on Android
**Solution:**
- Verify `google-services.json` is present
- Check `minSdkVersion >= 21`
- Ensure POST_NOTIFICATIONS permission

### 4. "SENDER_ID_MISMATCH"
**Solution:** 
- Delete app from device
- Verify `google-services.json` matches Firebase project
- Reinstall app

---

## ✅ Verification Checklist

- [ ] `firebase_messaging` in pubspec.yaml
- [ ] `google-services.json` in `android/app/`
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] Notification permissions in AndroidManifest.xml
- [ ] Push Notifications capability in Xcode
- [ ] APNs key uploaded to Firebase (iOS)
- [ ] Test on physical device
- [ ] FCM token appears in logs
- [ ] Test notification from Firebase Console works
- [ ] Ride request triggers notification

---

## 📚 Additional Resources

- [FlutterFire Messaging Docs](https://firebase.flutter.dev/docs/messaging/overview)
- [Firebase Console](https://console.firebase.google.com)
- [FCM Troubleshooting](https://firebase.google.com/docs/cloud-messaging/troubleshoot)

---

**Status:** ✅ Code Complete | ⚠️ Platform Setup Required
**Estimated Setup Time:** 30-60 minutes (per platform)
