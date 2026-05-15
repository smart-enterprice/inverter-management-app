import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import '../service/fcm_service.dart';
import '../service/local_notification_service.dart';

// ─── Convenience providers ────────────────────────────────────────────────────

/// Unread count badge — rebuilds only when count changes
final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// FCM connection status (true once token registered)
final fcmConnectedProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).isConnected;
});

// ─── Main Notifier ────────────────────────────────────────────────────────────

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);

class NotificationNotifier extends Notifier<NotificationState> {
  late final NotificationRepository _repo;
  late final LocalNotificationService _localNotif;
  late final FcmService _fcm;
  StreamSubscription<NotificationModel>? _fcmSub;
  String? _currentUserId;

  @override
  NotificationState build() {
    _repo = ref.read(notificationRepositoryProvider);
    _localNotif = LocalNotificationService();
    _fcm = FcmService();

    ref.onDispose(() => _fcmSub?.cancel());

    // Fire-and-forget init; state updates land via copyWith later.
    _init();

    return const NotificationState();
  }

  Future<void> _init() async {
    await _localNotif.initialize();
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('user_id');

    // Subscribe to FCM messages first so anything arriving during the
    // initial load isn't lost.
    _fcmSub?.cancel();
    _fcmSub = _fcm.notificationStream.listen(_onNewNotification);

    await _initFcm();
    // GET /notifications endpoint was removed by backend; skip the initial
    // list fetch until it returns. Restore with:
    // await loadNotifications(refresh: true);
  }

  Future<void> _initFcm() async {
    try {
      await _fcm.initialize(_repo);
      state = state.copyWith(isConnected: true);
    } catch (_) {
      state = state.copyWith(isConnected: false);
    }
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
    final updated = state.notifications.map((n) {
      if (n.notificationId == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final wasUnread = state.notifications
        .any((n) => n.notificationId == notificationId && !n.isRead);

    state = state.copyWith(
      notifications: updated,
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, 9999)
          : state.unreadCount,
    );

    await _repo.markAsRead(notificationId);
  }

  // ─── Mark all as read ─────────────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    state = state.copyWith(notifications: updated, unreadCount: 0);

    await _repo.markAllAsRead();
    await _localNotif.cancelAll();
  }

  // ─── New notification arrives via FCM ─────────────────────────────────────
  void _onNewNotification(NotificationModel notification) {
    final alreadyExists = state.notifications
        .any((n) => n.notificationId == notification.notificationId);

    if (!alreadyExists) {
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );
    }

    _localNotif.updateBadge(state.unreadCount);
  }
}
