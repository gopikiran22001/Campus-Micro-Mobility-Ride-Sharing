# 🛠️ FCM Commands Reference

Quick command reference for testing and deploying FCM notifications.

---

## 📦 Installation

```bash
# Install dependencies
flutter pub get

# Clean build (if issues)
flutter clean
flutter pub get
```

---

## 🧪 Testing

### Run App
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Specific device
flutter devices
flutter run -d <device-id>
```

### Check Logs
```bash
# Flutter logs
flutter logs

# Filter for FCM
flutter logs | grep "FCM"

# Filter for notifications
flutter logs | grep "Notification"
```

---

## 🔥 Firebase Commands

### Login
```bash
firebase login
```

### Initialize (if needed)
```bash
firebase init
# Select: Functions, Firestore
```

### Deploy Cloud Functions
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

### Deploy Everything
```bash
firebase deploy
```

### View Logs
```bash
# Cloud Function logs
firebase functions:log

# Follow logs (real-time)
firebase functions:log --only sendNotification
```

---

## 🧹 Cleanup

### Clear Flutter Cache
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Clear Firebase Cache
```bash
firebase logout
firebase login
```

### Reset Android Build
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

---

## 📱 Build Commands

### Android APK (Debug)
```bash
flutter build apk --debug
```

### Android APK (Release)
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS (Debug)
```bash
flutter build ios --debug
```

### iOS (Release)
```bash
flutter build ios --release
```

---

## 🧪 Test FCM with cURL

### Get Server Key
1. Firebase Console → Project Settings
2. Cloud Messaging → Server Key (Legacy)
3. Copy the key

### Send Test Notification
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test from cURL"
    },
    "data": {
      "type": "test",
      "timestamp": "2024-01-30"
    },
    "priority": "high"
  }'
```

### Send to Multiple Devices
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "registration_ids": ["TOKEN1", "TOKEN2", "TOKEN3"],
    "notification": {
      "title": "Broadcast Test",
      "body": "Sent to multiple devices"
    },
    "priority": "high"
  }'
```

---

## 🔍 Debugging

### Check FCM Token
```bash
# Run app and check console for:
# 📱 FCM Token: eXaMpLeToKeN...

# Or query Firestore
firebase firestore:get users/USER_ID
```

### Test Notification Permissions
```bash
# Android
adb shell dumpsys notification

# Check app permissions
adb shell pm list permissions -g
```

### Check Notification Channels (Android)
```bash
adb shell dumpsys notification | grep -A 5 "channel"
```

### View App Logs (Android)
```bash
adb logcat | grep "CampusGo"
adb logcat | grep "FCM"
```

---

## 📊 Firestore Queries

### Get User's FCM Token
```bash
firebase firestore:get users/USER_ID
```

### List Pending Notifications
```bash
firebase firestore:query notifications --where "sent==false"
```

### List Sent Notifications
```bash
firebase firestore:query notifications --where "sent==true" --limit 10
```

### Delete Test Notifications
```bash
# Use Firebase Console or write a script
```

---

## 🚀 Deployment Checklist

```bash
# 1. Test locally
flutter run
# Verify notifications work

# 2. Build release
flutter build apk --release  # Android
flutter build ios --release  # iOS

# 3. Deploy Cloud Functions
cd functions
npm install
cd ..
firebase deploy --only functions

# 4. Deploy Firestore rules
firebase deploy --only firestore:rules

# 5. Deploy indexes
firebase deploy --only firestore:indexes

# 6. Verify deployment
firebase functions:log
firebase firestore:indexes

# 7. Test on production
# Send test notification via Firebase Console
```

---

## 🔧 Troubleshooting Commands

### FCM Token Not Generated
```bash
flutter clean
flutter pub get
flutter run
# Check console for token
```

### Notifications Not Received
```bash
# Check permissions
adb shell dumpsys notification | grep "CampusGo"

# Check internet
adb shell ping google.com

# Restart app
flutter run
```

### Cloud Function Not Triggering
```bash
# Check deployment
firebase functions:list

# Check logs
firebase functions:log --only sendNotification

# Redeploy
firebase deploy --only functions
```

### Build Errors
```bash
# Clean everything
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter run
```

---

## 📝 Quick Reference

### Get FCM Token
```dart
// In app, check debug console for:
📱 FCM Token: eXaMpLeToKeN...
```

### Test via Firebase Console
1. Firebase Console → Cloud Messaging
2. "Send your first message"
3. Enter title and body
4. "Send test message"
5. Paste FCM token
6. Send

### Check Notification Delivery
```bash
# Firebase Console
Cloud Messaging → Reports

# Firestore
firebase firestore:query notifications --where "sent==true"

# Logs
firebase functions:log
```

---

## 🎯 Common Tasks

### Update Dependencies
```bash
flutter pub upgrade
flutter pub get
```

### Regenerate Firebase Config
```bash
# Download new google-services.json from Firebase Console
# Place in android/app/

# Download new GoogleService-Info.plist
# Place in ios/Runner/
```

### Reset Everything
```bash
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub cache repair
flutter pub get
flutter run
```

---

## 📚 Useful Links

- Firebase Console: https://console.firebase.google.com
- FCM Docs: https://firebase.google.com/docs/cloud-messaging
- Flutter Docs: https://docs.flutter.dev
- Pub.dev: https://pub.dev

---

**Quick Start:**
```bash
flutter pub get && flutter run
```

**Deploy to Production:**
```bash
firebase deploy && flutter build apk --release
```

**Check Everything:**
```bash
flutter doctor && firebase projects:list
```
