// functions/index.js
const { onDocumentCreated } = require("firebase-functions/v2/firestore"); // ✅ Sirf yeh chahiye
const admin = require("firebase-admin");
admin.initializeApp();

// ═══════════════════════════════════════════════════════════════
// 1. Vendor ko notify karo — naya order aaya
// ═══════════════════════════════════════════════════════════════
exports.notifyVendorOnNewOrder = onDocumentCreated("orders/{orderId}", async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const order = snap.data();
    const orderId = event.params.orderId;

    if (!order || !order.vendorId) return null;

    try {
        const vendorDoc = await admin.firestore().collection("vendors").doc(order.vendorId).get();

        if (!vendorDoc.exists) return null;

        const fcmToken = vendorDoc.data().fcmToken;
        if (!fcmToken) {
            console.log("No FCM token for vendor:", order.vendorId);
            return null;
        }

        const customerName = order.customerName || "Customer";
        const total = order.total ? order.total.toString() : "0";
        const itemCount = order.items ? order.items.length : 0;

        let itemSummary = "";
        if (order.items && order.items.length > 0) {
            const firstItems = order.items.slice(0, 2);
            itemSummary = firstItems.map((item) => `${item.quantity}x ${item.name}`).join(", ");
            if (order.items.length > 2) {
                itemSummary += ` +${order.items.length - 2} more`;
            }
        }

        const orderTime = new Date().toLocaleTimeString("en-IN", {
            hour: "2-digit",
            minute: "2-digit",
            hour12: true,
        });

        await admin.messaging().send({
            token: fcmToken,
            data: {
                orderId: orderId,
                type: "new_order",
                customerName: customerName,
                total: total,
                itemCount: itemCount.toString(),
                itemSummary: itemSummary,
                orderTime: orderTime,
            },
            android: {
                priority: "high",
                ttl: 3600000,
            },
            apns: {
                headers: {
                    "apns-priority": "10",
                },
                payload: {
                    aps: {
                        "content-available": 1,
                    },
                },
            },
        });

        console.log("✅ Notification sent to vendor:", order.vendorId);
        return null;
    } catch (error) {
        console.error("❌ Vendor notification error:", error);
        return null;
    }
});

// ═══════════════════════════════════════════════════════════════
// 2. Customer ko notify karo — notification document bani
// ═══════════════════════════════════════════════════════════════
exports.sendCustomerNotification = onDocumentCreated("notifications/{notificationId}", async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const data = snap.data();

    const customerId = data.customerId;
    const title = data.title;
    const message = data.message;
    const orderId = data.orderId || "";
    const type = data.type || "general";

    if (!customerId || !title || !message) {
        console.log("❌ Missing required fields");
        return null;
    }

    try {
        const customerDoc = await admin.firestore().collection("customers").doc(customerId).get();

        if (!customerDoc.exists) {
            console.log("❌ Customer not found:", customerId);
            return null;
        }

        const fcmToken = customerDoc.data().fcmToken;
        if (!fcmToken) {
            console.log("⚠️ No FCM token for customer:", customerId);
            return null;
        }

        // ✅ notification + data dono bhejo
        await admin.messaging().send({
            token: fcmToken,
            notification: {
                title: title,
                body: message,
            },
            data: {
                type: type,
                orderId: orderId,
                customerId: customerId,
                title: title,
                message: message,
            },
            android: {
                priority: "high",
                notification: {
                    channelId: "ironcreeze_orders",
                    sound: "default",
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                        alert: {
                            title: title,
                            body: message,
                        },
                    },
                },
            },
        });

        console.log("✅ Notification sent to customer:", customerId, "| type:", type);
        return null;
    } catch (error) {
        console.error("❌ Customer notification error:", error);
        return null;
    }
});