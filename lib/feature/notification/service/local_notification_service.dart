// lib/feature/notifications/service/local_notification_service.dart

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../model/notification_model.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
  LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Channel IDs are versioned (_v2) because Android channel settings are
  // immutable once created on a device — bumping the ID is the only way to
  // roll out new sound/vibration defaults to users who already installed.
  static const String _ordersChannelId = 'orders_channel_v2';
  static const String _productionChannelId = 'production_channel_v2';
  static const String _packingChannelId = 'packing_channel_v2';
  static const String _confirmedChannelId = 'confirmed_channel_v2';

  // ─── Initialize once at app startup ──────────────────────────────────────
  Future<void> initialize() async {
    // flutter_local_notifications does not support web — skip entirely
    if (kIsWeb) return;

    if (_initialized) return;

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await _createChannels(androidPlugin);
    }

    _initialized = true;
  }

  Future<void> _createChannels(
      AndroidFlutterLocalNotificationsPlugin? plugin) async {
    if (plugin == null) return;
    const channels = [
      AndroidNotificationChannel(
        _ordersChannelId,
        'Order Notifications',
        description: 'Order management notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        _productionChannelId,
        'Production Updates',
        description: 'Production stage updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        _packingChannelId,
        'Packing Updates',
        description: 'Packing stage updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        _confirmedChannelId,
        'Order Confirmations',
        description: 'Order confirmation alerts',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    ];
    for (final c in channels) {
      await plugin.createNotificationChannel(c);
    }
  }

  // ─── Show a notification from a NotificationModel ────────────────────────
  Future<void> showNotification(NotificationModel notification) async {
    if (kIsWeb) return;
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelIdForType(notification.type),
      _channelNameForType(notification.type),
      channelDescription: 'Order management notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(notification.message),
      groupKey: 'order_notifications',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = notification.notificationId.hashCode.abs() % 100000;

    await _plugin.show(
      id,
      notification.title,
      notification.message,
      details,
      payload: notification.notificationId,
    );
  }

  // ─── Update badge / summary notification ─────────────────────────────────
  Future<void> updateBadge(int count) async {
    if (kIsWeb) return;
    if (!_initialized) return;

    if (Platform.isAndroid && count > 0) {
      final summaryDetails = AndroidNotificationDetails(
        'order_summary',
        'Order Summary',
        channelDescription: 'Grouped order notifications',
        importance: Importance.low,
        priority: Priority.low,
        groupKey: 'order_notifications',
        setAsGroupSummary: true,
        silent: true,
      );
      await _plugin.show(
        0,
        'Smart Enterprises',
        '$count unread notifications',
        NotificationDetails(android: summaryDetails),
      );
    }
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  // ─── Channel mapping ──────────────────────────────────────────────────────
  String _channelIdForType(String type) {
    if (type.contains('PRODUCTION')) return _productionChannelId;
    if (type.contains('PACKED')) return _packingChannelId;
    if (type.contains('CONFIRMED')) return _confirmedChannelId;
    return _ordersChannelId;
  }

  String _channelNameForType(String type) {
    if (type.contains('PRODUCTION')) return 'Production Updates';
    if (type.contains('PACKED')) return 'Packing Updates';
    if (type.contains('CONFIRMED')) return 'Order Confirmations';
    return 'Order Notifications';
  }
}