import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handle background messages (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📨 Background message received: ${message.notification?.title}');
}

/// Push Notification Service for FCM
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Initialize local notifications (for foreground)
    await _initializeLocalNotifications();

    // Set up message handlers
    _setupMessageHandlers();

    // Save FCM token
    await _saveTokenToFirestore();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateTokenInFirestore);

    _isInitialized = true;
    debugPrint('✅ Push Notification Service initialized');
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'ride_updates',
              'Ride Updates',
              description: 'Notifications for ride updates and new riders',
              importance: Importance.high,
              playSound: true,
            ),
          );
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    // This would be called with a GlobalKey<NavigatorState> or GoRouter
    final type = data['type'] as String?;
    final rideId = data['rideId'] as String?;

    if (type == 'new_rider' && rideId != null) {
      // Navigate to ride chat
      debugPrint('Navigate to ride: $rideId');
      // context.push('/ride/$rideId/chat');
    }
  }

  /// Set up message handlers for foreground and opened app
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📬 Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // When app is opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '📱 App opened from notification: ${message.notification?.title}',
      );
      if (message.data.isNotEmpty) {
        _handleNotificationNavigation(message.data);
      }
    });

    // Check if app was opened from terminated state via notification
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          '🚀 App launched from notification: ${message.notification?.title}',
        );
        if (message.data.isNotEmpty) {
          _handleNotificationNavigation(message.data);
        }
      }
    });
  }

  /// Show local notification (for foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ride_updates',
          'Ride Updates',
          channelDescription: 'Notifications for ride updates and new riders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF6366F1),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Save FCM token to Firestore for the current user
  Future<void> _saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token;
      if (kIsWeb) {
        // For web, you need a VAPID key from Firebase Console
        // token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY');
        debugPrint('⚠️ Web push notifications require VAPID key setup');
        return;
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM Token saved for user: ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Update token when it refreshes
  Future<void> _updateTokenInFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM Token updated for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Subscribe to a topic (e.g., for a specific ride)
  Future<void> subscribeToRide(String rideId) async {
    await _messaging.subscribeToTopic('ride_$rideId');
    debugPrint('📌 Subscribed to ride_$rideId');
  }

  /// Unsubscribe from a ride topic
  Future<void> unsubscribeFromRide(String rideId) async {
    await _messaging.unsubscribeFromTopic('ride_$rideId');
    debugPrint('📌 Unsubscribed from ride_$rideId');
  }

  /// Get current FCM token (for debugging)
  Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await _messaging.getToken();
  }
}
