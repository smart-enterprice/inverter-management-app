

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../network/dio_client.dart';
import '../model/notification_model.dart';


final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final dio = ref.read(dioClientProvider);
  return NotificationRepository(dio);
});

class NotificationRepository {
  final Dio _dio;
  StreamController<NotificationModel>? _sseController;
  StreamController<int>? _unreadCountController;

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

  // ─── SSE Stream ──────────────────────────────────────────────────────────
  // Returns a broadcast stream of new notifications arriving via SSE.
  // We use http (dart:io) directly so we can stream line-by-line
  // without Dio buffering the whole response.
  Stream<NotificationModel> connectToSSE() {
    _sseController?.close();
    _sseController = StreamController<NotificationModel>.broadcast();
    _startSSE();
    return _sseController!.stream;
  }

  Stream<int> get unreadCountStream {
    _unreadCountController ??=
    StreamController<int>.broadcast();
    return _unreadCountController!.stream;
  }

  void _emitUnreadCount(int count) {
    if (_unreadCountController?.isClosed == false) {
      _unreadCountController!.add(count);
    }
  }

  Future<void> _startSSE() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? ''; // same key as _tokenKey in your login provider

      // Use Dio's responseType = stream to get chunked SSE data
      final response = await _dio.get<ResponseBody>(
        '/notifications/stream',
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: Duration.zero,   // ← disables timeout for SSE
          sendTimeout: Duration.zero,      // ← disables send timeout too
          headers: {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final stream = response.data!.stream;
      StringBuffer buffer = StringBuffer();

      stream.listen(
            (chunk) {
          final text = utf8.decode(chunk, allowMalformed: true);
          buffer.write(text);

          // SSE messages are separated by double newline
          while (buffer.toString().contains('\n\n')) {
            final content = buffer.toString();
            final idx = content.indexOf('\n\n');
            final block = content.substring(0, idx);
            buffer = StringBuffer(content.substring(idx + 2));
            _processSSEBlock(block);
          }
        },
        onError: (e) {
          debugPrint('SSE stream error: $e');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('SSE stream closed — reconnecting...');
          _scheduleReconnect();
        },
      );
    } catch (e) {
      debugPrint('SSE connect error: $e');
      _scheduleReconnect();
    }
  }

  void _processSSEBlock(String block) {
    String? eventType;
    String? dataStr;

    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataStr = line.substring(5).trim();
      }
    }

    if (dataStr == null || dataStr.isEmpty) return;

    try {
      final json = jsonDecode(dataStr) as Map<String, dynamic>;

      // Connection established event → emit initial unread count
      if (eventType == 'connected' || json.containsKey('unread_count')) {
        final count = json['unread_count'];
        if (count is int) _emitUnreadCount(count);
        return;
      }

      // New notification event
      if (json.containsKey('notification_id') || json.containsKey('_id')) {
        final notification = NotificationModel.fromJson(json);
        if (_sseController?.isClosed == false) {
          _sseController!.add(notification);
        }
      }
    } catch (e) {
      debugPrint('SSE parse error: $e | data: $dataStr');
    }
  }

  Timer? _reconnectTimer;

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_sseController?.isClosed == false) {
        _startSSE();
      }
    });
  }

  void disposeSSE() {
    _reconnectTimer?.cancel();
    _sseController?.close();
    _unreadCountController?.close();
    _sseController = null;
    _unreadCountController = null;
  }
}