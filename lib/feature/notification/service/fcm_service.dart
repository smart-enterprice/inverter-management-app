import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import 'local_notification_service.dart';

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotif = LocalNotificationService();

  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  Stream<NotificationModel> get notificationStream =>
      _notificationController.stream;

  NotificationRepository? _repo;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  // ─── Initialize FCM and register token with backend ──────────────────────
  Future<void> initialize(NotificationRepository repo) async {
    if (kIsWeb) return;
    _repo = repo;

    await _localNotif.initialize();

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_initialized) {
      _onMessageSub = FirebaseMessaging.onMessage.listen(_handleForeground);
      _onMessageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedApp);
      _tokenRefreshSub =
          _messaging.onTokenRefresh.listen(_handleTokenRefresh);

      // App launched from a terminated state via notification tap
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _emitFromMessage(initialMessage);
      }

      _initialized = true;
    }

    await _registerCurrentToken();
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token unavailable');
        return;
      }
      debugPrint('FCM token: $token');
      await _registerWithBackend(token);
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    debugPrint('FCM token refreshed: $newToken');
    await _registerWithBackend(newToken);
  }

  Future<void> _registerWithBackend(String token) async {
    final deviceId = await _resolveDeviceId();
    final appVersion = await _resolveAppVersion();
    await _repo?.registerFcmToken(
      token: token,
      platform: platformName,
      deviceId: deviceId,
      appVersion: appVersion,
    );
  }

  Future<String> _resolveDeviceId() async {
    try {
      final info = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return web.vendor ?? web.userAgent ?? 'web-unknown';
      }
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.id;
      }
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? 'ios-unknown';
      }
    } catch (e) {
      debugPrint('device id resolve error: $e');
    }
    return 'unknown';
  }

  Future<String> _resolveAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      debugPrint('app version resolve error: $e');
      return 'unknown';
    }
  }

  // ─── Foreground: app is open — show banner via local notifications ──────
  void _handleForeground(RemoteMessage message) {
    debugPrint('[FCM] ← onMessage data=${message.data} '
        'notif=${message.notification?.title}/${message.notification?.body}');
    final notification = _parseRemoteMessage(message);
    if (notification == null) {
      debugPrint('[FCM] onMessage parsed to null — skipping');
      return;
    }

    _localNotif.showNotification(notification);
    _notificationController.add(notification);
  }

  // ─── User tapped a notification while app was in background ─────────────
  void _handleOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] ← onMessageOpenedApp data=${message.data}');
    _emitFromMessage(message);
  }

  void _emitFromMessage(RemoteMessage message) {
    final notification = _parseRemoteMessage(message);
    if (notification != null) {
      _notificationController.add(notification);
    }
  }

  // ─── Parse FCM RemoteMessage into NotificationModel ─────────────────────
  // Reads from message.data first (data block), falls back to
  // message.notification (title/body) so this works whether the backend
  // sends data-only, notification-only, or both.
  NotificationModel? _parseRemoteMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final notif = message.notification;

      final title = (data['title'] as String?) ?? notif?.title ?? '';
      final body = (data['message'] as String?) ??
          (data['body'] as String?) ??
          notif?.body ??
          '';

      if (title.isEmpty && body.isEmpty) return null;

      // FCM data values are always strings — payload may arrive as JSON
      Map<String, dynamic> payloadMap = {};
      final rawPayload = data['payload'];
      if (rawPayload is String && rawPayload.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawPayload);
          if (decoded is Map) {
            payloadMap = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      } else if (rawPayload is Map) {
        payloadMap = Map<String, dynamic>.from(rawPayload);
      }

      List<String> targetRoles = [];
      final rawRoles = data['target_roles'];
      if (rawRoles is String && rawRoles.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawRoles);
          if (decoded is List) {
            targetRoles = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {}
      } else if (rawRoles is List) {
        targetRoles = rawRoles.map((e) => e.toString()).toList();
      }

      return NotificationModel(
        id: data['_id'] ?? data['notification_id'] ?? '',
        notificationId: data['notification_id'] ?? '',
        type: data['type'] ?? '',
        title: title,
        message: body,
        payload: payloadMap,
        targetRoles: targetRoles,
        readBy: const [],
        createdBy: data['created_by'] ?? '',
        createdAt:
            DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
        updatedAt:
            DateTime.tryParse(data['updated_at'] ?? '') ?? DateTime.now(),
        isRead: false,
      );
    } catch (e) {
      debugPrint('FCM parse error: $e');
      return null;
    }
  }

  // ─── Called on logout — clear local FCM token only ──────────────────────
  // Backend deregister endpoint was removed; backend handles token cleanup
  // server-side. We still delete the local token so this device stops
  // receiving pushes tied to the old session.
  Future<void> clearLocalToken() async {
    try {
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM deleteToken error: $e');
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
    await _notificationController.close();
  }

  String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
