import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import '../../core/const/icons.dart';
import '../../core/media_query/media_query.dart';
import '../../feature/brand/screen/brands_page.dart';
import '../../feature/product/screen/products_screen.dart';
import '../../feature/signup/screen/dealer/dealers_screen.dart';
import '../../feature/signup/screen/user/users_screen.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);

    final List<Map<String, dynamic>> items = [
      {
        'title': 'New Order',
        'icon': AppIcons.add,
        'accent': const Color(0xFF1B4FD8),
        'bg': const Color(0xFFEEF2FF),
        'border': const Color(0xFFC7D2FE),
        'page': const OrderCreatePage(),
      },
      {
        'title': 'Products',
        'icon': AppIcons.product,
        'accent': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'border': const Color(0xFFDDD6FE),
        'page': const ProductsScreen(),
      },
      {
        'title': 'Brands',
        'icon': AppIcons.brand,
        'accent': const Color(0xFFEA580C),
        'bg': const Color(0xFFFFF7ED),
        'border': const Color(0xFFFED7AA),
        'page': const BrandsScreen(),
      },
      {
        'title': 'Dealers',
        'icon': AppIcons.dealers,
        'accent': const Color(0xFF0A8A5C),
        'bg': const Color(0xFFEDFAF4),
        'border': const Color(0xFF9FE0C5),
        'page': const DealersScreen(),
      },
      {
        'title': 'Users',
        'icon': AppIcons.dealers,
        'accent': const Color(0xFF4338CA),
        'bg': const Color(0xFFEEF2FF),
        'border': const Color(0xFFC7D2FE),
        'page': const UsersScreen(),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: EdgeInsets.only(
                right: i < items.length - 1 ? sw * 0.03 : 0),
            child: _QuickAccessCard(
              sw: sw,
              title: item['title'],
              iconPath: item['icon'],
              accent: item['accent'],
              bg: item['bg'],
              border: item['border'],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item['page']),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAccessCard extends StatefulWidget {
  final double sw;
  final String title, iconPath;
  final Color accent, bg, border;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.sw,
    required this.title,
    required this.iconPath,
    required this.accent,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.93).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final cardW = sw * 0.22;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: cardW,
          padding: EdgeInsets.symmetric(
              vertical: sw * 0.04, horizontal: sw * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(sw * 0.04),
            border: Border.all(color: widget.border),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: sw * 0.12,
                height: sw * 0.12,
                decoration: BoxDecoration(
                  color: widget.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.border, width: 1.5),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    widget.iconPath,
                    width: sw * 0.052,
                    height: sw * 0.052,
                    colorFilter: ColorFilter.mode(
                        widget.accent, BlendMode.srcIn),
                  ),
                ),
              ),
              SizedBox(height: sw * 0.025),

              // Label
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: sw * 0.028,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}