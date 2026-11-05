import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

/// Service managing high-priority local notifications, full-screen lock screen intents,
/// and background audible heads-up alerts for online DOGO captains.
class DogoNotificationService {
  static final DogoNotificationService _instance = DogoNotificationService._internal();
  static DogoNotificationService get instance => _instance;

  DogoNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int rideNotificationId = 8888;
  static const int arrivalNotificationId = 9999;
  static const String channelId = 'dogo_ride_dispatch_channel_v1';
  static const String channelName = 'DOGO Incoming Ride Requests';
  static const String channelDesc =
      'High-priority heads-up alerts for online captains when ride requests arrive';

  /// Initializes notification channels, Android permissions, and click handlers
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Notification tapped: brings app to the foreground
      },
    );

    // Create high-importance Android channel with custom vibration & full-screen intent
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Request notification permissions for Android 13+ (API 33+)
      await androidPlugin.requestNotificationsPermission();

      final androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
      );

      await androidPlugin.createNotificationChannel(androidChannel);
    }

    _initialized = true;
  }

  /// Displays a fullScreenIntent high-priority heads-up notification for an incoming ride
  Future<void> showIncomingRideNotification({
    required String rideCode,
    required String pickup,
    required String dropoff,
    required int fare,
    required String vehicleType,
    int durationSecs = 15,
  }) async {
    try {
      final formattedFare = '₦${NumberFormat('#,###').format(fare)}';

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: '🚨 Incoming DOGO Ride: $formattedFare',
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
        color: const Color(0xFF2563EB),
        styleInformation: BigTextStyleInformation(
          '📍 Pickup: $pickup\n🏁 Dropoff: $dropoff\n💰 Net Payout: $formattedFare\n⏱️ $durationSecs seconds to accept this request!',
          contentTitle: '🚨 New Ride Request: $formattedFare',
          summaryText: '${vehicleType.toUpperCase()} #$rideCode',
        ),
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notifications.show(
        id: rideNotificationId,
        title: '🚨 New Ride Request: $formattedFare',
        body: '$pickup → $dropoff ($durationSecs seconds to accept)',
        notificationDetails: details,
        payload: rideCode,
      );
    } catch (_) {}
  }

  /// Dismisses / cancels the incoming ride alert notification
  Future<void> cancelRideNotification() async {
    try {
      await _notifications.cancel(id: rideNotificationId);
    } catch (_) {}
  }

  /// Shows arrival notification to passenger when captain reaches pickup
  Future<void> showPassengerArrivalNotification({
    required String captainName,
    required String vehicleInfo,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'dogo_trip_updates',
        'DOGO Trip Updates',
        channelDescription: 'Real-time updates regarding your ongoing ride or parcel delivery',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notifications.show(
        id: arrivalNotificationId,
        title: '🚕 Your Captain Has Arrived!',
        body: '$captainName in $vehicleInfo has arrived at your pickup point.',
        notificationDetails: details,
      );
    } catch (_) {}
  }
}
