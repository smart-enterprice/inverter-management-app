import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../network/dio_client.dart';
import '../model/notification_model.dart';


final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return NotificationRepository(dio);
});

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  // ─── Fetch paginated notifications ───────────────────────────────────────
  Future<({bool hasMore, List<NotificationModel> notifications, dynamic total})>
  fetchNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = response.data['data'];
      final List<dynamic> raw = data['notifications'] ?? [];
      final total = data['total'] ?? 0;
      final notifications =
      raw.map((e) => NotificationModel.fromJson(e)).toList();
      return (
      notifications: notifications,
      total: total,
      hasMore: (page * limit) < total,
      );
    } catch (e) {
      debugPrint('fetchNotifications error: $e');
      rethrow;
    }
  }

  // ─── Mark a single notification as read ──────────────────────────────────
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response =
      await _dio.put('/notifications/$notificationId/read');
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('markAsRead error: $e');
      return false;
    }
  }

  // ─── Mark all as read ────────────────────────────────────────────────────
  Future<bool> markAllAsRead() async {
    try {
      final response = await _dio.put('/notifications/mark-all-read');
      return response.data['success'] == true;
    } catch (e) {
      debugPrint('markAllAsRead error: $e');
      return false;
    }
  }

  // ─── Get unread count ────────────────────────────────────────────────────
  Future<int> fetchUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['data']['count'] ?? 0;
    } catch (e) {
      debugPrint('fetchUnreadCount error: $e');
      return 0;
    }
  }

  // ─── Register FCM token with backend ─────────────────────────────────────
  // POST /notifications/devices
  // body: {token, platform, device_id, app_version}
  Future<bool> registerFcmToken({
    required String token,
    required String platform,
    required String deviceId,
    required String appVersion,
  }) async {
    debugPrint('[FCM] → POST /notifications/devices');
    try {
      final response = await _dio.post(
        '/notifications/devices',
        data: {
          'token': token,
          'platform': platform,
          'device_id': deviceId,
          'app_version': appVersion,
        },
      );
      final ok = response.data['success'] == true;
      debugPrint('[FCM] ← devices status=${response.statusCode} success=$ok');
      return ok;
    } catch (e) {
      debugPrint('[FCM] ✗ registerFcmToken error: $e');
      return false;
    }
  }
}
