const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Cloud Function to send FCM notifications
 * Triggers when a new document is created in 'notifications' collection
 *
 * SPARK PLAN COMPATIBLE (GEN-1)
 */
exports.sendNotification = functions.firestore
    .document("notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();

      if (!notification) {
        console.error("❌ Notification document is empty");
        return null;
      }

      // Skip if already sent
      if (notification.sent === true) {
        console.log("⏭️ Notification already sent, skipping");
        return null;
      }

      const {fcmToken, title, body, data} = notification;

      if (!fcmToken || typeof fcmToken !== "string") {
        console.error("❌ Invalid or missing FCM token");
        return null;
      }

      // Convert data payload to strings (FCM requirement)
      const dataPayload = {};
      if (data && typeof data === "object") {
        for (const key of Object.keys(data)) {
          dataPayload[key] = String(data[key]);
        }
      }

      const message = {
        token: fcmToken,
        notification: {
          title: title || "CampusGo",
          body: body || "",
        },
        data: dataPayload,
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        const messageId = await admin.messaging().send(message);

        console.log("✅ Notification sent");
        console.log("📨 Message ID:", messageId);

        await snap.ref.update({
          sent: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          messageId: messageId,
        });

        return null;
      } catch (error) {
        console.error("❌ Error sending notification");
        console.error("Code:", error.code);
        console.error("Message:", error.message);

        await snap.ref.update({
          error: error.message,
          errorCode: error.code || "unknown",
          errorAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return null;
      }
    });
