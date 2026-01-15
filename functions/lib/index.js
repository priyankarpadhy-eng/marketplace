"use strict";
/**
 * Firebase Cloud Functions for Marketplace
 *
 * This file contains the Cloud Functions that handle push notifications
 * when users interact with rides.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendChatNotification = exports.sendRideNotification = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
/**
 * Triggered when a new ride notification is created.
 * Sends push notification to the ride creator and other participants.
 */
exports.sendRideNotification = functions.firestore
    .document("ride_notifications/{notificationId}")
    .onCreate(async (snap, context) => {
    const notification = snap.data();
    // Check if already processed
    if (notification.processed) {
        console.log("Notification already processed, skipping.");
        return null;
    }
    const { type, rideId, joinerId, joinerName, creatorId, destination, participantIds, } = notification;
    console.log(`Processing ${type} notification for ride ${rideId}`);
    // Get tokens for all participants (except the joiner)
    const tokensToNotify = [];
    const usersToNotify = [creatorId, ...participantIds].filter((id) => id !== joinerId);
    // Remove duplicates
    const uniqueUsers = [...new Set(usersToNotify)];
    // Fetch FCM tokens for each user
    for (const userId of uniqueUsers) {
        try {
            const userDoc = await db.collection("users").doc(userId).get();
            const userData = userDoc.data();
            if (userData === null || userData === void 0 ? void 0 : userData.fcmToken) {
                tokensToNotify.push(userData.fcmToken);
            }
        }
        catch (error) {
            console.error(`Error getting token for user ${userId}:`, error);
        }
    }
    if (tokensToNotify.length === 0) {
        console.log("No tokens to send notifications to.");
        // Mark as processed anyway
        await snap.ref.update({ processed: true });
        return null;
    }
    console.log(`Sending notifications to ${tokensToNotify.length} devices`);
    // Build the notification message
    const message = {
        tokens: tokensToNotify,
        notification: {
            title: "🚗 New Rider Joined!",
            body: `${joinerName} has joined your ride to ${destination}. Check it out!`,
        },
        data: {
            type: "new_rider",
            rideId: rideId,
            joinerId: joinerId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
            notification: {
                channelId: "ride_updates",
                priority: "high",
                defaultSound: true,
                defaultVibrateTimings: true,
                icon: "@mipmap/ic_launcher",
                color: "#6366F1",
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
        const response = await messaging.sendEachForMulticast(message);
        console.log(`Successfully sent ${response.successCount} notifications, ` +
            `${response.failureCount} failures`);
        // Log any failures
        if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
                var _a, _b;
                if (!resp.success) {
                    console.error(`Failed to send to token ${tokensToNotify[idx]}: `, resp.error);
                    // If token is invalid, remove it from the user document
                    if (((_a = resp.error) === null || _a === void 0 ? void 0 : _a.code) === "messaging/invalid-registration-token" ||
                        ((_b = resp.error) === null || _b === void 0 ? void 0 : _b.code) === "messaging/registration-token-not-registered") {
                        // Find and remove the invalid token
                        removeInvalidToken(tokensToNotify[idx]);
                    }
                }
            });
        }
    }
    catch (error) {
        console.error("Error sending multicast message:", error);
    }
    // Mark notification as processed
    await snap.ref.update({ processed: true, processedAt: admin.firestore.FieldValue.serverTimestamp() });
    return null;
});
/**
 * Helper function to remove invalid FCM tokens from user documents
 */
async function removeInvalidToken(invalidToken) {
    try {
        const usersSnapshot = await db
            .collection("users")
            .where("fcmToken", "==", invalidToken)
            .get();
        const batch = db.batch();
        usersSnapshot.docs.forEach((doc) => {
            batch.update(doc.ref, {
                fcmToken: admin.firestore.FieldValue.delete(),
            });
        });
        await batch.commit();
        console.log(`Removed invalid token: ${invalidToken.substring(0, 20)}...`);
    }
    catch (error) {
        console.error("Error removing invalid token:", error);
    }
}
/**
 * Optional: Send notification when a new chat message is sent in a ride
 */
exports.sendChatNotification = functions.firestore
    .document("rides/{rideId}/chat/{messageId}")
    .onCreate(async (snap, context) => {
    const { rideId } = context.params;
    const message = snap.data();
    const { senderId, senderName, message: msgContent } = message;
    // Get the ride to find all participants
    const rideDoc = await db.collection("rides").doc(rideId).get();
    if (!rideDoc.exists)
        return null;
    const ride = rideDoc.data();
    if (!ride)
        return null;
    // Get tokens for all participants except the sender
    const tokensToNotify = [];
    const participants = ride.participants || [];
    for (const participant of participants) {
        if (participant.userId !== senderId) {
            try {
                const userDoc = await db.collection("users").doc(participant.userId).get();
                const userData = userDoc.data();
                if (userData === null || userData === void 0 ? void 0 : userData.fcmToken) {
                    tokensToNotify.push(userData.fcmToken);
                }
            }
            catch (error) {
                console.error(`Error getting token for user ${participant.userId}:`, error);
            }
        }
    }
    if (tokensToNotify.length === 0) {
        return null;
    }
    // Send notification
    const notificationMessage = {
        tokens: tokensToNotify,
        notification: {
            title: `💬 ${senderName}`,
            body: msgContent.length > 100 ? msgContent.substring(0, 100) + "..." : msgContent,
        },
        data: {
            type: "chat_message",
            rideId: rideId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
            notification: {
                channelId: "ride_updates",
                priority: "default",
                defaultSound: true,
            },
        },
    };
    try {
        await messaging.sendEachForMulticast(notificationMessage);
        console.log(`Chat notification sent for ride ${rideId}`);
    }
    catch (error) {
        console.error("Error sending chat notification:", error);
    }
    return null;
});
//# sourceMappingURL=index.js.map