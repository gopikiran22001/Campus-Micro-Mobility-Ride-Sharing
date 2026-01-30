# 🔔 Notification Messages Reference

Complete list of all notification types in CampusGo with their exact titles and messages.

---

## 📱 Notification Types

### 1. New Ride Request (to Rider)
**Trigger:** When a student requests a ride and rider is matched

**Title:** `New Ride Request 🚴`  
**Text:** `{StudentName} needs a ride to {Destination}`  
**Data:** `{ type: "ride_request", rideId: "..." }`

**Example:**
```
Title: New Ride Request 🚴
Text: Alice needs a ride to Library
```

---

### 2. Ride Confirmed (to Student)
**Trigger:** When rider accepts the ride request

**Title:** `Ride Confirmed 🚲`  
**Text:** `Your ride has been accepted. The rider will arrive shortly.`  
**Data:** `{ type: "ride_accepted", rideId: "..." }`

**Example:**
```
Title: Ride Confirmed 🚲
Text: Your ride has been accepted. The rider will arrive shortly.
```

---

### 3. Rider Skipped Request (to Student)
**Trigger:** When rider doesn't respond within 2 minutes

**Title:** `Searching for Another Rider`  
**Text:** `This rider skipped your request. Looking for the next available rider.`  
**Data:** `{ type: "rider_skipped", rideId: "..." }`

**Example:**
```
Title: Searching for Another Rider
Text: This rider skipped your request. Looking for the next available rider.
```

---

### 4. Matching in Progress (to Student) - Optional
**Trigger:** When actively searching for riders

**Title:** `Finding You a Ride ⏳`  
**Text:** `We're checking nearby riders. Please hold on for a moment.`  
**Data:** `{ type: "matching_in_progress", rideId: "..." }`

**Example:**
```
Title: Finding You a Ride ⏳
Text: We're checking nearby riders. Please hold on for a moment.
```

---

### 5. No Ride Available (to Student)
**Trigger:** When no riders found after 6 minutes

**Title:** `No Ride Available 🚫`  
**Text:** `No riders are available right now. Try again in a few minutes.`  
**Data:** `{ type: "no_match" }`

**Example:**
```
Title: No Ride Available 🚫
Text: No riders are available right now. Try again in a few minutes.
```

---

### 6. Ride Cancelled (to Both)
**Trigger:** When either party cancels the ride

**Title:** `Ride Cancelled 🚨`  
**Text:** `The ride has been cancelled. You can request a new ride anytime.`  
**Data:** `{ type: "ride_cancelled" }`

**Example:**
```
Title: Ride Cancelled 🚨
Text: The ride has been cancelled. You can request a new ride anytime.
```

---

### 7. Ride Started (to Both)
**Trigger:** When rider starts the ride

**Title:** `Ride Started 🚀`  
**Text:** `Your ride with {OtherUserName} has started. Have a safe journey!`  
**Data:** `{ type: "ride_started" }`

**Example:**
```
Title: Ride Started 🚀
Text: Your ride with John has started. Have a safe journey!
```

---

### 8. Ride Completed (to Both)
**Trigger:** When rider marks ride as complete

**Title:** `Ride Completed 🎉`  
**Text:** `Your ride is complete. Thank you for using CampusGo!`  
**Data:** `{ type: "ride_completed" }`

**Example:**
```
Title: Ride Completed 🎉
Text: Your ride is complete. Thank you for using CampusGo!
```

---

## 📊 Notification Flow by User Type

### Student Journey
```
1. Request Ride
   ↓
2. [Optional] "Finding You a Ride ⏳"
   ↓
3a. "Ride Confirmed 🚲" (if accepted)
   OR
3b. "Searching for Another Rider" (if skipped)
   OR
3c. "No Ride Available 🚫" (if no match)
   ↓
4. "Ride Started 🚀"
   ↓
5. "Ride Completed 🎉"

Cancellation Path:
- "Ride Cancelled 🚨" (at any point)
```

### Rider Journey
```
1. "New Ride Request 🚴"
   ↓
2. Accept or Skip
   ↓
3. "Ride Started 🚀"
   ↓
4. "Ride Completed 🎉"

Cancellation Path:
- "Ride Cancelled 🚨" (if student cancels)
```

---

## 🎨 Notification Styling

### Emojis Used
- 🚴 - New ride request (bike/rider)
- 🚲 - Ride confirmed (bicycle)
- ⏳ - Matching in progress (hourglass)
- 🚫 - No ride available (prohibited)
- 🚨 - Ride cancelled (alert)
- 🚀 - Ride started (rocket)
- 🎉 - Ride completed (celebration)

### Tone Guidelines
- **Positive:** Confirmed, Started, Completed
- **Informative:** New Request, Matching, Searching
- **Neutral:** Cancelled, No Available
- **Reassuring:** All messages end with helpful context

---

## 🔧 Implementation Details

### Notification Service Functions

```dart
// To Rider
notifyRiderOfNewRequest(riderId, studentName, destination, rideId)

// To Student
notifyStudentOfAcceptance(studentId, riderName, rideId)
notifyStudentOfRiderSkipped(studentId, rideId)
notifyStudentOfMatchingInProgress(studentId, rideId)
notifyStudentOfNoMatch(studentId)
notifyStudentOfCancellation(studentId, riderName)

// To Both
notifyRideStarted(userId, otherUserName)
notifyRideCompleted(userId, otherUserName)

// To Rider (cancellation)
notifyRiderOfCancellation(riderId, studentName)
```

---

## 📝 Customization Guide

### To Change a Notification Message:

1. Open `lib/core/services/notification_service.dart`
2. Find the function (e.g., `notifyStudentOfAcceptance`)
3. Update the `title` and `body` parameters
4. Save and rebuild

**Example:**
```dart
Future<void> notifyStudentOfAcceptance({
  required String studentId,
  required String riderName,
  required String rideId,
}) async {
  await sendNotificationToUser(
    userId: studentId,
    title: 'Ride Confirmed 🚲',  // ← Change this
    body: 'Your ride has been accepted. The rider will arrive shortly.',  // ← Change this
    data: {'type': 'ride_accepted', 'rideId': rideId},
  );
}
```

---

## 🧪 Testing Notifications

### Test Each Type:

1. **New Ride Request:**
   - Student requests ride
   - Check Rider device

2. **Ride Confirmed:**
   - Rider accepts request
   - Check Student device

3. **Rider Skipped:**
   - Wait 2 minutes without accepting
   - Check Student device

4. **No Ride Available:**
   - Request ride with no riders available
   - Wait 6 minutes
   - Check Student device

5. **Ride Cancelled:**
   - Cancel ride after request
   - Check other party's device

6. **Ride Started:**
   - Start ride after acceptance
   - Check both devices

7. **Ride Completed:**
   - Complete ride
   - Check both devices

---

## 🌍 Localization (Future)

To add multiple languages:

1. Create notification message constants
2. Use Flutter's `intl` package
3. Update notification service to use localized strings

**Example Structure:**
```dart
class NotificationMessages {
  static String rideConfirmedTitle(String locale) {
    switch (locale) {
      case 'en': return 'Ride Confirmed 🚲';
      case 'es': return 'Viaje Confirmado 🚲';
      case 'hi': return 'राइड की पुष्टि 🚲';
      default: return 'Ride Confirmed 🚲';
    }
  }
}
```

---

## 📊 Analytics Tracking

Track notification effectiveness:

```dart
// Add to notification service
void _trackNotificationSent(String type) {
  // Firebase Analytics
  FirebaseAnalytics.instance.logEvent(
    name: 'notification_sent',
    parameters: {'type': type},
  );
}

// Add to notification tap handler
void _trackNotificationOpened(String type) {
  FirebaseAnalytics.instance.logEvent(
    name: 'notification_opened',
    parameters: {'type': type},
  );
}
```

---

## 🎯 Best Practices

### Do's ✅
- Keep messages concise (under 100 characters)
- Use emojis for visual appeal
- Provide actionable context
- Be consistent with tone
- Test on multiple devices

### Don'ts ❌
- Don't use technical jargon
- Don't make messages too long
- Don't overuse emojis
- Don't send duplicate notifications
- Don't include sensitive information

---

## 📱 Platform-Specific Notes

### Android
- Notifications show in status bar
- Can be expanded for more details
- Supports action buttons (future enhancement)
- Grouped by channel

### iOS
- Notifications show as banners
- Can be expanded with 3D Touch
- Supports notification actions
- Requires physical device for testing

---

## 🔄 Future Enhancements

### Planned Features:
1. **Action Buttons:**
   - "Accept" / "Decline" in notification
   - "View Details" button

2. **Rich Notifications:**
   - Show rider photo
   - Display map preview
   - Show estimated time

3. **Sound Customization:**
   - Different sounds for different types
   - Custom notification tones

4. **Priority Levels:**
   - High: New request, Cancellation
   - Medium: Confirmed, Started
   - Low: Completed

---

**Last Updated:** January 30, 2024  
**Version:** 1.0  
**Status:** ✅ Production Ready
