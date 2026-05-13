// lib/screen/tablet_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/role/app_role.dart';
import '../../feature/authentication/controller/login_controller.dart';
import '../../feature/authentication/screen/login_mobile_view.dart';
import '../../feature/notification/provider/notification_provider.dart';
// import '../../feature/notification/view/notification_screen.dart'; // hidden bell
import '../../feature/signup/controller/signUp_controller.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP      = Color(0xFF185FA5);
const _kPBg    = Color(0xFFEBF4FF);
const _kPBd    = Color(0xFFBFD9F5);
const _kBg     = Color(0xFFF7F8FA);
const _kWhite  = Colors.white;
const _kBd     = Color(0xFFE5E7EB);
const _kT1     = Color(0xFF111827);
const _kT2     = Color(0xFF374151);
const _kT3     = Color(0xFF6B7280);
const _kRed    = Color(0xFFDC2626);
const _kRedBg  = Color(0xFFFEF2F2);

// Sidebar dimensions — fixed, no mid-animation values
const double _kSideExp = 220.0;
const double _kSideCol =  72.0;
const Duration _kDur   = Duration(milliseconds: 180);

// ── Nav item model ────────────────────────────────────────────────────────────
class TabletNavItem {
  const TabletNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge,
  });
  final String   label;
  final IconData icon;
  final IconData activeIcon;
  final int?     badge;
}

// ═════════════════════════════════════════════════════════════════════════════
// TabletShell
// ═════════════════════════════════════════════════════════════════════════════
class TabletShell extends ConsumerStatefulWidget {
  const TabletShell({
    super.key,
    required this.pages,
    required this.navItems,
    this.initialIndex = 0,
  });
  final List<Widget>        pages;
  final List<TabletNavItem> navItems;
  final int                 initialIndex;

  @override
  ConsumerState<TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<TabletShell> {
  late int _idx;
  bool     _expanded = true;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex.clamp(0, widget.pages.length - 1);
  }

  void _select(int i) {
    if (i == _idx) return;
    HapticFeedback.selectionClick();
    setState(() => _idx = i);
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  Future<void> _logout() async {
    final res = await ref.read(loginControllerProvider.notifier).logout();
    if (!mounted) return;
    if (res.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginMobileView()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Row(
          children: [

            // ── Sidebar ──────────────────────────────────────────────────
            // AnimatedContainer animates the CLIP width only.
            // OverflowBox ensures _Sidebar always lays out at full _kSideExp
            // width — no mid-animation size mismatch ever.
            RepaintBoundary(
              child: ClipRect(
                child: AnimatedContainer(
                  duration: _kDur,
                  curve: Curves.easeInOut,
                  width: _expanded ? _kSideExp : _kSideCol,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth:  _kSideExp,
                    maxWidth:  _kSideExp,
                    child: _Sidebar(
                      expanded: _expanded,
                      items:    widget.navItems,
                      selected: _idx,
                      sh:       sh,
                      onSelect: _select,
                      onToggle: _toggle,
                      onLogout: _logout,
                    ),
                  ),
                ),
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────
            Container(width: 0.5, color: _kBd),

            // ── Main content ──────────────────────────────────────────────
            Expanded(
              child: RepaintBoundary(
                child: Column(
                  children: [
                    _TopBar(sh: sh),
                    Expanded(
                      child: IndexedStack(
                        index: _idx,
                        children: widget.pages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Sidebar  — always built at _kSideExp width
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.expanded,
    required this.items,
    required this.selected,
    required this.sh,
    required this.onSelect,
    required this.onToggle,
    required this.onLogout,
  });
  final bool                expanded;
  final List<TabletNavItem> items;
  final int                 selected;
  final double              sh;
  final ValueChanged<int>   onSelect;
  final VoidCallback        onToggle;
  final VoidCallback        onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kSideExp,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _kWhite),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Logo
            _Logo(expanded: expanded, sh: sh),
            _hLine(),
            SizedBox(height: sh * 0.014),

            // Nav items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: _kSideExp * 0.06),
                itemCount: items.length,
                itemBuilder: (_, i) => _NavTile(
                  item:     items[i],
                  active:   i == selected,
                  expanded: expanded,
                  sh:       sh,
                  onTap:    () => onSelect(i),
                ),
              ),
            ),

            _hLine(),
            SizedBox(height: sh * 0.008),

            // Collapse
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _kSideExp * 0.06),
              child: _ActionTile(
                icon:     expanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                label:    'Collapse',
                expanded: expanded,
                sh:       sh,
                fg:       _kT3,
                bg:       _kBg,
                onTap:    onToggle,
              ),
            ),
            SizedBox(height: sh * 0.005),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: _kSideExp * 0.06),
              child: _ActionTile(
                icon:     Icons.logout_rounded,
                label:    'Logout',
                expanded: expanded,
                sh:       sh,
                fg:       _kRed,
                bg:       _kRedBg,
                onTap:    onLogout,
              ),
            ),
            SizedBox(height: sh * 0.022),
          ],
        ),
      ),
    );
  }

  Widget _hLine() => Container(
    height: 0.5, color: _kBd,
    margin: const EdgeInsets.symmetric(
        horizontal: _kSideExp * 0.08),
  );
}

// ── Logo ──────────────────────────────────────────────────────────────────────
class _Logo extends StatelessWidget {
  const _Logo({required this.expanded, required this.sh});
  final bool   expanded;
  final double sh;

  @override
  Widget build(BuildContext context) {
    // icon size fixed at max clamp since width is always _kSideExp
    const sz = 38.0;
    // When collapsed the clip shows _kSideCol px; center icon there.
    final hPad = expanded
        ? _kSideExp * 0.09
        : (_kSideCol - sz) / 2.0;

    return SizedBox(
      height: (sh * 0.1).clamp(60.0, 80.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Icon
            Container(
              width: sz, height: sz,
              decoration: BoxDecoration(
                color:        _kPBg,
                borderRadius: BorderRadius.circular(sz * 0.26),
                border:       Border.all(color: _kPBd, width: 0.5),
              ),
              padding: const EdgeInsets.all(sz * 0.15),
              child: Image.asset(
                'assets/logo/smart_icon.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.bolt_rounded, size: sz * 0.6, color: _kP),
              ),
            ),
            // Text — only shown when expanded (OverflowBox clips it otherwise)
            if (expanded) ...[
              const SizedBox(width: _kSideExp * 0.06),
              Expanded(
                child: Column(
                  mainAxisAlignment:  MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Smart',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize:      15.0,
                          fontWeight:    FontWeight.w800,
                          color:         _kP,
                          letterSpacing: -0.3,
                          height:        1.1,
                        )),
                    Text('Enterprises',
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize:      11.0,
                          fontWeight:    FontWeight.w500,
                          color:         _kT3,
                          letterSpacing: 0.2,
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Nav tile ──────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.active,
    required this.expanded,
    required this.sh,
    required this.onTap,
  });
  final TabletNavItem item;
  final bool          active, expanded;
  final double        sh;
  final VoidCallback  onTap;

  // fixed sizes — sidebar is always _kSideExp wide
  static const _iconSz  = 20.0;
  static const _labelFs = 13.0;
  // collapsed: center icon in _kSideCol visible clip
  // formula: (_kSideCol - _iconSz) / 2  - listview_padding(_kSideExp * 0.06)
  static const _colHPad = (_kSideCol - _iconSz) / 2 - _kSideExp * 0.06;
  static const _expHPad = _kSideExp * 0.1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _kDur,
        margin:  EdgeInsets.only(bottom: sh * 0.005),
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? _expHPad : _colHPad.clamp(0.0, _expHPad),
          vertical:   sh * 0.013,
        ),
        decoration: BoxDecoration(
          color:        active ? _kPBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: _kPBd, width: 0.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            // Icon + badge
            Stack(clipBehavior: Clip.none, children: [
              Icon(
                active ? item.activeIcon : item.icon,
                size:  _iconSz,
                color: active ? _kP : _kT3,
              ),
              if ((item.badge ?? 0) > 0)
                Positioned(
                  top: -3, right: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:        _kRed,
                      borderRadius: BorderRadius.circular(7),
                      border:       Border.all(color: _kWhite, width: 1.5),
                    ),
                    child: Text(
                      '${(item.badge ?? 0) > 99 ? "99+" : item.badge}',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 8,
                        fontWeight: FontWeight.w800, height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ]),

            // Label + active pill
            if (expanded) ...[
              const SizedBox(width: _kSideExp * 0.06),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize:   _labelFs,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color:      active ? _kP : _kT2,
                    height:     1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (active)
                Container(
                  width: 3, height: 18,
                  decoration: BoxDecoration(
                    color:        _kP,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action tile (collapse / logout) ──────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.sh,
    required this.fg,
    required this.bg,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final bool         expanded;
  final double       sh;
  final Color        fg, bg;
  final VoidCallback onTap;

  static const _iconSz  = 18.0;
  static const _labelFs = 12.0;
  static const _colHPad = (_kSideCol - _iconSz) / 2 - _kSideExp * 0.06;
  static const _expHPad = _kSideExp * 0.1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? _expHPad : _colHPad.clamp(0.0, _expHPad),
          vertical:   sh * 0.011,
        ),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, size: _iconSz, color: fg),
            if (expanded) ...[
              const SizedBox(width: _kSideExp * 0.06),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize:   _labelFs,
                      fontWeight: FontWeight.w600,
                      color:      fg,
                    )),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends ConsumerWidget {
  const _TopBar({required this.sh});
  final double sh;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user    = ref.watch(currentUserProvider).asData?.value;
    // Keep notificationProvider alive so FcmService.initialize() runs (bell hidden, pushes still work).
    ref.watch(notificationProvider);
    final role    = ref.watch(roleNotifierProvider);
    final name    = (user?.employeeName ?? '').replaceAll('_', ' ').trim();
    final display = name.isEmpty ? '...' : name;
    final photo   = (user?.photo?.isNotEmpty ?? false) ? user!.photo : null;

    final barH    = (sh * 0.135).clamp(86.0, 108.0);
    final arSz    = (sh * 0.038).clamp(24.0, 32.0);
    final greetFs = (sh * 0.018).clamp(10.0, 12.5);
    final nameFs  = (sh * 0.028).clamp(14.0, 18.0);
    final subFs   = (sh * 0.018).clamp(10.0, 12.5);
    // final iconSz  = (sh * 0.032).clamp(18.0, 24.0); // bell-only, hidden
    // final btnSz   = (sh * 0.058).clamp(36.0, 46.0); // bell-only, hidden
    final hPad    = (sh * 0.024).clamp(16.0, 28.0);

    return Container(
      height: barH,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: const BoxDecoration(
        color:  _kWhite,
        border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
      ),
      child: Row(children: [

        // Greeting / name / role — stacked, one per line
        Expanded(
          child: Column(
            mainAxisAlignment:  MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(
                _greeting,
                style: TextStyle(
                  fontSize:   greetFs,
                  fontWeight: FontWeight.w500,
                  color:      _kT3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: sh * 0.003),
              Text(
                display,
                style: TextStyle(
                  fontSize:      nameFs,
                  fontWeight:    FontWeight.w800,
                  color:         _kT1,
                  letterSpacing: -0.3,
                  height:        1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: sh * 0.005),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sh * 0.011, vertical: sh * 0.003),
                decoration: BoxDecoration(
                  color:        _kPBg,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: _kPBd, width: 0.5),
                ),
                child: Text(role.displayName,
                    style: TextStyle(
                      fontSize:   subFs,
                      fontWeight: FontWeight.w600,
                      color:      _kP,
                    )),
              ),
            ],
          ),
        ),

        // Notification bell (hidden — backend list endpoint removed; restore when it returns)
        /*
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationScreen())),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: btnSz, height: btnSz,
              decoration: BoxDecoration(
                color:  _kPBg, shape: BoxShape.circle,
                border: Border.all(color: _kPBd, width: 0.5),
              ),
              child: Icon(Icons.notifications_outlined,
                  size: iconSz, color: _kP),
            ),
            if (unread > 0)
              Positioned(
                top: -2, right: -2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color:        _kRed,
                    borderRadius: BorderRadius.circular(8),
                    border:       Border.all(color: _kWhite, width: 1.5),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 9,
                      fontWeight: FontWeight.w800, height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ]),
        ),
        SizedBox(width: sh * 0.018),
        */

        // Avatar
        Container(
          width:  arSz * 2, height: arSz * 2,
          decoration: BoxDecoration(
            shape:  BoxShape.circle, color: _kPBg,
            border: Border.all(color: _kPBd, width: 1.5),
          ),
          child: ClipOval(
            child: photo != null
                ? Image.network(photo, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(display, arSz))
                : _initials(display, arSz),
          ),
        ),
      ]),
    );
  }

  Widget _initials(String name, double r) {
    final init = name.split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      color: _kPBg,
      child: Center(
        child: Text(init, style: TextStyle(
          fontSize:   r * 0.65,
          fontWeight: FontWeight.w800,
          color:      _kP,
        )),
      ),
    );
  }
}

