

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import '../service/local_notification_service.dart';

// ─── Convenience providers ────────────────────────────────────────────────────

/// Unread count badge — rebuilds only when count changes
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// SSE connection status
final sseConnectedProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).isConnected;
});

// ─── Main Notifier ────────────────────────────────────────────────────────────

final notificationProvider =
StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.read(notificationRepositoryProvider);
  final localNotif = LocalNotificationService();
  return NotificationNotifier(repo, localNotif);
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  final LocalNotificationService _localNotif;
  StreamSubscription? _sseSub;
  StreamSubscription? _unreadSub;
  String? _currentUserId;

  NotificationNotifier(this._repo, this._localNotif)
      : super(const NotificationState()) {
    _init();
  }

  Future<void> _init() async {
    await _localNotif.initialize();
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id'); // matches _userIdKey in your login provider

    // Load initial data & connect SSE in parallel
    await Future.wait([
      loadNotifications(),
      _connectSSE(),
    ]);
  }

  // ─── Load / Paginate ───────────────────────────────────────────────────────
  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.fetchNotifications(page: page);

      // Mark notifications as read for current user
      final enriched = result.notifications.map((n) {
        final readByMe = _currentUserId != null &&
            n.readBy.any((r) => r.employeeId == _currentUserId);
        return n.copyWith(isRead: readByMe);
      }).toList();

      state = state.copyWith(
        notifications: refresh
            ? enriched
            : [...state.notifications, ...enriched],
        hasMore: result.hasMore,
        currentPage: page + 1,
        isLoading: false,
      );

      // Fetch fresh unread count from server
      final count = await _repo.fetchUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications',
      );
    }
  }

  Future<void> refresh() => loadNotifications(refresh: true);

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadNotifications();
  }

  // ─── Mark single as read ──────────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      if (n.notificationId == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final wasUnread =
    state.notifications.any((n) => n.notificationId == notificationId && !n.isRead);

    state = state.copyWith(
      notifications: updated,
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, 9999)
          : state.unreadCount,
    );

    // Sync with server
    await _repo.markAsRead(notificationId);
  }

  // ─── Mark all as read ─────────────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    // Optimistic update
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    state = state.copyWith(notifications: updated, unreadCount: 0);

    await _repo.markAllAsRead();
    await _localNotif.cancelAll();
  }

  // ─── SSE Connection ───────────────────────────────────────────────────────
  Future<void> _connectSSE() async {
    state = state.copyWith(isConnected: false);

    // Listen to unread count updates from SSE
    _unreadSub?.cancel();
    _unreadSub = _repo.unreadCountStream.listen((count) {
      state = state.copyWith(unreadCount: count);
    });

    // Listen to new notifications
    _sseSub?.cancel();
    _sseSub = _repo.connectToSSE().listen(
          (notification) async {
        state = state.copyWith(isConnected: true);
        _onNewNotification(notification);
      },
      onError: (_) => state = state.copyWith(isConnected: false),
    );
  }

  void _onNewNotification(NotificationModel notification) {
    // Prepend to list (newest first)
    final alreadyExists =
    state.notifications.any((n) => n.notificationId == notification.notificationId);

    if (!alreadyExists) {
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );
    }

    // Show local push notification (status bar)
    _localNotif.showNotification(notification);
    _localNotif.updateBadge(state.unreadCount);
  }

  // ─── Called when user logs out ────────────────────────────────────────────
  void dispose() {
    _sseSub?.cancel();
    _unreadSub?.cancel();
    _repo.disposeSSE();
    super.dispose();
  }
}