import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../widgets/circle_button.dart';
import '../model/notification_model.dart';
import '../provider/notification_provider.dart';

// ── Zoho Books design tokens (unified with the rest of the app) ───────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

// ── Notification type helpers ─────────────────────────────────────────────────
IconData _iconForType(String type) {
  if (type.contains('PACKED'))     return Icons.inventory_2_outlined;
  if (type.contains('PRODUCTION')) return Icons.precision_manufacturing_outlined;
  if (type.contains('CONFIRMED'))  return Icons.check_circle_outline_rounded;
  if (type.contains('PENDING'))    return Icons.hourglass_empty_outlined;
  return Icons.notifications_outlined;
}

Color _colorForType(String type) {
  if (type.contains('PACKED'))     return _kPurple;
  if (type.contains('PRODUCTION')) return _kAmber;
  if (type.contains('CONFIRMED'))  return _kGreen;
  if (type.contains('PENDING'))    return _kP;
  return _kT4;
}

Color _bgForType(String type) {
  if (type.contains('PACKED'))     return _kPurpleBg;
  if (type.contains('PRODUCTION')) return _kAmberBg;
  if (type.contains('CONFIRMED'))  return _kGreenBg;
  if (type.contains('PENDING'))    return _kPBg;
  return _kBg;
}

Color _bdForType(String type) {
  if (type.contains('PACKED'))     return _kPurpleBd;
  if (type.contains('PRODUCTION')) return _kAmberBd;
  if (type.contains('CONFIRMED'))  return _kGreenBd;
  if (type.contains('PENDING'))    return _kPBd;
  return _kBd;
}

String _labelForType(String type) {
  if (type.contains('PACKED'))     return 'Packed';
  if (type.contains('PRODUCTION')) return 'In Production';
  if (type.contains('CONFIRMED'))  return 'Confirmed';
  if (type.contains('PENDING'))    return 'Pending';
  return type.replaceAll('ORDER_', '').replaceAll('_', ' ').toLowerCase();
}

// ═════════════════════════════════════════════════════════════════════════════
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(notificationProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw      = MediaQuery.sizeOf(context).width;
    final sh      = MediaQuery.sizeOf(context).height;
    final state   = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [

        // ── App Bar ────────────────────────────────────────────────────
        Container(
          color:   _kWhite,
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context)),
            const Spacer(),

            // Title + unread count
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Notifications',
                  style: TextStyle(
                      fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight:   FontWeight.w700,
                      color:        _kT1,
                      letterSpacing: -0.2)),
              if (state.unreadCount > 0) ...[
                SizedBox(width: sw * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.025).clamp(8.0, 12.0),
                      vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                  decoration: BoxDecoration(
                      color:        _kRed,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${state.unreadCount}',
                      style: TextStyle(
                          color:      _kWhite,
                          fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ]),
            const Spacer(),

            // Right-side actions
            Row(mainAxisSize: MainAxisSize.min, children: [
              // Live / reconnecting dot
              Tooltip(
                message: state.isConnected ? 'Live' : 'Reconnecting…',
                child: Container(
                  width:  (sw * 0.022).clamp(7.0, 10.0),
                  height: (sw * 0.022).clamp(7.0, 10.0),
                  decoration: BoxDecoration(
                      color: state.isConnected ? _kGreen : _kAmber,
                      shape: BoxShape.circle),
                ),
              ),
              if (state.unreadCount > 0) ...[
                SizedBox(width: sw * 0.025),
                GestureDetector(
                  onTap: notifier.markAllAsRead,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.025).clamp(8.0, 12.0),
                        vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                    decoration: BoxDecoration(
                        color:        _kPBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPBd, width: 0.5)),
                    child: Text('Mark all read',
                        style: TextStyle(
                            fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                            fontWeight: FontWeight.w700,
                            color:      _kP)),
                  ),
                ),
              ],
            ]),
          ]),
        ),

        // ── Body ──────────────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color:           _kP,
            backgroundColor: _kWhite,
            onRefresh:       notifier.refresh,
            child: state.isLoading && state.notifications.isEmpty
                ? const Center(
                child: CircularProgressIndicator(
                    color: _kP, strokeWidth: 2.5))
                : state.notifications.isEmpty
                ? _EmptyState(sw: sw, sh: sh)
                : ListView.builder(
              controller: _scrollCtrl,
              physics:    const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  sw * 0.038, sh * 0.012,
                  sw * 0.038, sh * 0.04),
              itemCount: state.notifications.length +
                  (state.hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == state.notifications.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: sh * 0.02),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: _kP, strokeWidth: 2.5),
                    ),
                  );
                }
                return _NotificationCard(
                  sw:           sw,
                  notification: state.notifications[i],
                  onTap: () => notifier.markAsRead(
                      state.notifications[i].notificationId),
                );
              },
            ),
          ),
        ),
      ])),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _NotificationCard — mirrors _BrandCard / _UserCard layout
// ═════════════════════════════════════════════════════════════════════════════
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.sw,
    required this.notification,
    required this.onTap,
  });

  final double            sw;
  final NotificationModel notification;
  final VoidCallback      onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final type     = notification.type;
    final color    = _colorForType(type);
    final bg       = _bgForType(type);
    final bd       = _bdForType(type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(bottom: sw * 0.025),
        decoration: BoxDecoration(
            color:        isUnread ? bg : _kWhite,
            borderRadius: BorderRadius.circular(
                (sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(
                color: isUnread ? bd : _kBd,
                width: isUnread ? 1.0 : 0.5)),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.038),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Type icon badge ────────────────────────────────────
              Container(
                width:  (sw * 0.1).clamp(36.0, 48.0),
                height: (sw * 0.1).clamp(36.0, 48.0),
                decoration: BoxDecoration(
                    color:        bg,
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    border: Border.all(color: bd, width: 0.5)),
                child: Icon(_iconForType(type),
                    size:  (sw * 0.048).clamp(16.0, 22.0),
                    color: color),
              ),
              SizedBox(width: sw * 0.03),

              // ── Content ────────────────────────────────────────────
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(notification.title,
                                style: TextStyle(
                                    fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: _kT1,
                                    letterSpacing: -0.1)),
                          ),
                          SizedBox(width: sw * 0.02),
                          Text(
                            timeago.format(notification.createdAt),
                            style: TextStyle(
                                fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                                color:      _kT4,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: sw * 0.01),

                      // Message
                      Text(notification.message,
                          style: TextStyle(
                              fontSize:   (sw * 0.031).clamp(10.5, 14.0),
                              color:      _kT2,
                              fontWeight: FontWeight.w400,
                              height:     1.4)),
                      SizedBox(height: sw * 0.015),

                      // Type pill
                      Row(children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: (sw * 0.02).clamp(6.0, 10.0),
                              vertical:   (sw * 0.006).clamp(2.0, 4.5)),
                          decoration: BoxDecoration(
                              color:        bg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: bd, width: 0.5)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_iconForType(type),
                                size:  (sw * 0.026).clamp(9.0, 11.5),
                                color: color),
                            SizedBox(width: sw * 0.008),
                            Text(_labelForType(type),
                                style: TextStyle(
                                    fontSize:   (sw * 0.024).clamp(8.5, 11.0),
                                    fontWeight: FontWeight.w700,
                                    color:      color)),
                          ]),
                        ),
                      ]),
                    ]),
              ),

              // ── Unread dot ─────────────────────────────────────────
              if (isUnread)
                Padding(
                  padding: EdgeInsets.only(left: sw * 0.02, top: sw * 0.01),
                  child: Container(
                    width:  (sw * 0.02).clamp(6.0, 9.0),
                    height: (sw * 0.02).clamp(6.0, 9.0),
                    decoration: const BoxDecoration(
                        color: _kRed, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _EmptyState
// ═════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width:  (sw * 0.22).clamp(72.0, 100.0),
        height: (sw * 0.22).clamp(72.0, 100.0),
        decoration: BoxDecoration(
            color:  _kWhite,
            shape:  BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.notifications_off_outlined,
            size:  (sw * 0.11).clamp(36.0, 48.0), color: _kT4),
      ),
      SizedBox(height: sh * 0.02),
      Text('No notifications yet',
          style: TextStyle(
              fontSize:   (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w700,
              color:      _kT2)),
      SizedBox(height: sh * 0.006),
      Text('You\'re all caught up!',
          style: TextStyle(
              fontSize: (sw * 0.031).clamp(10.5, 14.0), color: _kT4)),
    ]),
  );
}