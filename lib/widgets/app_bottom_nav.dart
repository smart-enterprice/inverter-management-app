import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens (colours only — no sizes) ───────────────────────────────────
const _kPrimary       = Color(0xFF185FA5);
const _kBg            = Color(0xFFFFFFFF);
const _kBorder        = Color(0xFFE5E7EB);
const _kIconInactive  = Color(0xFF9CA3AF);
const _kLabelActive   = Color(0xFF185FA5);
const _kLabelInactive = Color(0xFF6B7280);
const _kIndicator     = Color(0xFFEBF4FF);

// ── Nav item model ────────────────────────────────────────────────────────────
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// ── Tab presets ───────────────────────────────────────────────────────────────

/// SUPER_ADMIN · ADMIN · SALESMAN · MANAGER
const List<AppNavItem> kStandardNavItems = [
  AppNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  AppNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
  ),
  AppNavItem(
    label: 'Create',
    icon: Icons.add_circle_outline_rounded,
    activeIcon: Icons.add_circle_rounded,
  ),
  AppNavItem(
    label: 'Today',
    icon: Icons.today_outlined,
    activeIcon: Icons.today_rounded,
  ),
];

/// PRODUCTION · PACKING · DELIVERY · ACCOUNTS
const List<AppNavItem> kLimitedNavItems = [
  AppNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  AppNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
  ),
  AppNavItem(
    label: 'Today',
    icon: Icons.today_outlined,
    activeIcon: Icons.today_rounded,
  ),
];

// ── AppBottomNav ──────────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = kStandardNavItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;

  @override
  Widget build(BuildContext context) {
    final mq     = MediaQuery.of(context);
    final sw     = mq.size.width;
    final sh     = mq.size.height;

    // Bar height: 7.5% of screen height, clamped between 6.5%–8.5%
    // Works on SE (568pt) through large phones (932pt) and tablets
    final barH   = (sh * 0.075).clamp(sh * 0.065, sh * 0.085);

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      // SafeArea adds home-indicator space automatically — do NOT add it manually
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: SizedBox(
          height: barH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavTab(
                  item: items[i],
                  isActive: i == currentIndex,
                  sw: sw,
                  sh: sh,
                  barH: barH,
                  onTap: () {
                    if (i != currentIndex) {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Single tab ────────────────────────────────────────────────────────────────
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.isActive,
    required this.sw,
    required this.sh,
    required this.barH,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isActive;
  final double sw;   // screen width
  final double sh;   // screen height
  final double barH; // computed bar height
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // All sizes derived from screen dimensions — no fixed px anywhere
    final iconSize  = (sw * 0.058).clamp(18.0, 26.0);
    final fontSize  = (sw * 0.028).clamp(9.0, 12.0);
    final pillHPad  = (sw * 0.04).clamp(10.0, 20.0);
    final pillVPad  = (sh * 0.005).clamp(2.0, 5.0);
    final gap       = (sh * 0.004).clamp(1.0, 4.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Icon with active indicator pill ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: pillHPad,
              vertical: pillVPad,
            ),
            decoration: BoxDecoration(
              color: isActive ? _kIndicator : Colors.transparent,
              borderRadius: BorderRadius.circular(sw * 0.05),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                size: iconSize,
                color: isActive ? _kPrimary : _kIconInactive,
              ),
            ),
          ),
          SizedBox(height: gap),
          // ── Label ─────────────────────────────────────────────────────────
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? _kLabelActive : _kLabelInactive,
              letterSpacing: 0.1,
              height: 1.0, // removes extra line-height that causes overflow
            ),
            child: Text(item.label, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

// ── RoleShell ─────────────────────────────────────────────────────────────────
/// Scaffold wrapper used by every role mobile view.
/// IndexedStack + AppBottomNav — built once, used by all 9 roles.
class RoleShell extends StatelessWidget {
  const RoleShell({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onTap,
    this.navItems = kStandardNavItems,
  });

  final List<Widget> pages;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> navItems;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;

    // Tablet: width > 600 — could switch to a side rail here in future
    final isTablet = sw >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      // On tablet we still use bottom nav for now (side rail = Phase 2 of rework)
      bottomNavigationBar: isTablet
          ? _TabletNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: navItems,
        sw: sw,
      )
          : AppBottomNav(
        currentIndex: currentIndex,
        onTap: onTap,
        items: navItems,
      ),
    );
  }
}

// ── Tablet bottom nav (wider pills, slightly taller bar) ──────────────────────
class _TabletNavBar extends StatelessWidget {
  const _TabletNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.sw,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavItem> items;
  final double sw;

  @override
  Widget build(BuildContext context) {
    final sh   = MediaQuery.sizeOf(context).height;
    // Tablet bar is a touch taller — 6% of height
    final barH = (sh * 0.06).clamp(52.0, 72.0);

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: SizedBox(
          height: barH,
          // On tablet, tabs are centred with max width so they don't stretch
          // across the full 768–1024px width and look too spread out
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: sw * 0.65),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(items.length, (i) {
                  return Expanded(
                    child: _NavTab(
                      item: items[i],
                      isActive: i == currentIndex,
                      sw: sw,
                      sh: sh,
                      barH: barH,
                      onTap: () {
                        if (i != currentIndex) {
                          HapticFeedback.selectionClick();
                          onTap(i);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}