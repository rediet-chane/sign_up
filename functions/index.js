const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ region: "us-central1" }); // change if your project uses a different region

/**
 * Fires whenever UserService.createVendorSignupNotification() (or anything
 * else) creates a doc in /notifications.
 *
 * This replaces the old client -> Render server -> FCM flow. The admin's
 * fcmToken never has to be readable by other clients, and there's no
 * public HTTP endpoint anyone can hit to spam notifications.
 */
exports.sendVendorSignupPush = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notification = snap.data();
    const { adminId, message, vendorName, vendorEmail, type } = notification;

    if (!adminId) {
      console.log("No adminId on notification doc, skipping.");
      return;
    }

    const adminDoc = await admin.firestore().collection("users").doc(adminId).get();
    if (!adminDoc.exists) {
      console.log(`Admin ${adminId} not found.`);
      return;
    }

    const fcmToken = adminDoc.data().fcmToken;
    if (!fcmToken) {
      console.log(`Admin ${adminId} has no fcmToken saved.`);
      return;
    }

    const payload = {
      token: fcmToken,
      notification: {
        title: "New Vendor Signup!",
        body: message || `${vendorName} (${vendorEmail}) wants to join as a vendor`,
      },
      data: {
        type: type || "vendor_signup",
        notificationId: event.params.notificationId,
      },
      android: {
        notification: {
          channelId: "vendor_alerts",
        },
      },
    };

    try {
      await admin.messaging().send(payload);
      console.log(`✅ Push sent to admin ${adminId}`);
    } catch (err) {
      console.error(`❌ Failed to send push to admin ${adminId}:`, err);
    }
  }
);