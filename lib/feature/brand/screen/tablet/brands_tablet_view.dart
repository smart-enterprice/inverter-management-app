// lib/feature/brand/screen/tablet/brands_tablet_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/const/icons.dart';
import '../../../../model/brand_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../../brand/controller/brand_controller.dart';
import '../brand_details_page.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF4F5F7);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kBdLight  = Color(0xFFF0F1F3);
const _kT1       = Color(0xFF111827);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

Color _sc(String? s) => s?.toLowerCase() == 'active' ? _kGreen : _kRed;
Color _sb(String? s) => s?.toLowerCase() == 'active' ? _kGreenBg : _kRedBg;
Color _sd(String? s) => s?.toLowerCase() == 'active' ? _kGreenBd : _kRedBd;

// ═════════════════════════════════════════════════════════════════════════════
class BrandsTabletView extends ConsumerStatefulWidget {
  const BrandsTabletView({super.key});
  @override
  ConsumerState<BrandsTabletView> createState() => _State();
}

class _State extends ConsumerState<BrandsTabletView> {
  final _ctrl = TextEditingController();
  String     _q         = '';
  String?    _status;   // null=All, 'active', 'inactive'
  BrandModel? _sel;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<BrandModel> _filter(List<BrandModel> src) => src.where((b) {
    if (_status != null && b.status?.toLowerCase() != _status) return false;
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();
    return b.brandName.toLowerCase().contains(q) ||
        (b.description ?? '').toLowerCase().contains(q) ||
        b.brandModels.any((m) => m.toLowerCase().contains(q));
  }).toList();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final lw = (sw * 0.38).clamp(260.0, 420.0);

    final async$ = ref.watch(brandControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────────
          _TopBar(
            sw: sw, sh: sh, ctrl: _ctrl, q: _q,
            onChanged: (v) => setState(() { _q = v; _sel = null; }),
            onClear:   ()  => setState(() { _ctrl.clear(); _q = ''; _sel = null; }),
            onRefresh: ()  => ref.invalidate(brandControllerProvider),
          ),

          // ── Filter bar ───────────────────────────────────────────────────
          _FilterBar(
            sw: sw, sh: sh, status: _status,
            onStatus: (v) => setState(() { _status = v; _sel = null; }),
          ),

          // ── Split view ───────────────────────────────────────────────────
          Expanded(child: async$.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
            error: (_, __) => _ErrView(
                onRetry: () => ref.invalidate(brandControllerProvider)),
            data: (brands) {
              final list = _filter(brands);
              if (_sel == null && list.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _sel == null) setState(() => _sel = list.first);
                });
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // LEFT — brand list
                SizedBox(
                  width: lw,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    child: list.isEmpty
                        ? _EmptyLeft(lw: lw)
                        : ListView.builder(
                      padding: EdgeInsets.only(top: sh * 0.008),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _BrandRow(
                        brand:    list[i],
                        selected: _sel?.brandId == list[i].brandId,
                        lw: lw,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = list[i]);
                        },
                      ),
                    ),
                  ),
                ),

                // RIGHT — detail
                Expanded(
                  child: _sel == null
                      ? _EmptyRight(rw: sw - lw)
                      : _DetailCard(
                    brand: _sel!,
                    rw: sw - lw, sh: sh,
                    onOpen: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            BrandDetailsScreen(brandId: _sel!.brandId!))),
                  ),
                ),
              ]);
            },
          )),
        ]),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.sw, required this.sh, required this.ctrl,
    required this.q, required this.onChanged, required this.onClear,
    required this.onRefresh});
  final double sw, sh;
  final TextEditingController ctrl;
  final String q;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear, onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    height: (sh * 0.085).clamp(52.0, 64.0),
    decoration: const BoxDecoration(
      color: _kWhite,
      border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
    ),
    padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
    child: Row(children: [
      CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () => Navigator.pop(context)),
      SizedBox(width: sw * 0.016),
      Text('Brands', style: TextStyle(
        fontSize: (sw * 0.022).clamp(16.0, 20.0),
        fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3,
      )),
      SizedBox(width: sw * 0.02),
      Expanded(child: _SearchField(ctrl: ctrl, sw: sw, sh: sh,
          hint: 'Search brands…', onChanged: onChanged, onClear: onClear)),
      SizedBox(width: sw * 0.012),
      GestureDetector(
        onTap: onRefresh,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _kPBg, borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kPBd, width: 0.5),
          ),
          child: const Icon(Icons.refresh_rounded, size: 16, color: _kP),
        ),
      ),
    ]),
  );
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.sw, required this.sh,
    required this.status, required this.onStatus});
  final double sw, sh;
  final String? status;
  final ValueChanged<String?> onStatus;

  @override
  Widget build(BuildContext context) => Container(
    height: (sh * 0.058).clamp(38.0, 48.0),
    decoration: const BoxDecoration(
      color: _kWhite,
      border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
    ),
    padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
    child: Row(children: [
      _Chip(label: 'All',      active: status == null,       onTap: () => onStatus(null)),
      const SizedBox(width: 6),
      _Chip(label: 'Active',   active: status == 'active',   onTap: () => onStatus('active')),
      const SizedBox(width: 6),
      _Chip(label: 'Inactive', active: status == 'inactive', onTap: () => onStatus('inactive')),
    ]),
  );
}

// ── Brand list row ────────────────────────────────────────────────────────────
class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.brand, required this.selected,
    required this.lw, required this.onTap});
  final BrandModel brand;
  final bool selected;
  final double lw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: selected ? _kPBg : _kWhite,
          border: Border(
            left:   BorderSide(color: selected ? _kP : Colors.transparent, width: 3),
            bottom: const BorderSide(color: _kBdLight, width: 0.5),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: lw * 0.06, vertical: 11),
        child: Row(children: [
          // Brand icon
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _kPurpleBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kPurpleBd, width: 0.5),
            ),
            child: Center(
              child: SvgPicture.asset(
                AppIcons.brand,
                width: 16,
                colorFilter: const ColorFilter.mode(_kPurple, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: lw * 0.04),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(brand.brandName, style: TextStyle(
              fontSize: (lw * 0.042).clamp(12.0, 14.0),
              fontWeight: FontWeight.w700,
              color: selected ? _kP : _kT1,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${brand.brandModels.length} model${brand.brandModels.length != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: (lw * 0.032).clamp(9.5, 11.0),
                color: _kT4, fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          _StatusBadge(status: brand.status),
        ]),
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.brand, required this.rw,
    required this.sh, required this.onOpen});
  final BrandModel brand;
  final double rw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pad = (rw * 0.06).clamp(18.0, 32.0);
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header card ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _kWhite, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Gray header section
            Container(
              padding: EdgeInsets.all(pad),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _kPurpleBg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kPurpleBd, width: 0.5),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.brand, width: 22,
                      colorFilter: const ColorFilter.mode(_kPurple, BlendMode.srcIn),
                    ),
                  ),
                ),
                SizedBox(width: pad * 0.6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(brand.brandName, style: TextStyle(
                    fontSize: (rw * 0.032).clamp(15.0, 20.0),
                    fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.2,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if ((brand.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(brand.description!, style: const TextStyle(
                        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ])),
                _StatusBadge(status: brand.status),
              ]),
            ),

            // ── Brand details section ──────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionLabel('BRAND OVERVIEW'),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.label_outline_rounded,
                  label: 'Brand Name',
                  value: brand.brandName,
                ),
                if ((brand.description ?? '').isNotEmpty) ...[
                  const _Divider(),
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Description',
                    value: brand.description!,
                  ),
                ],
                const _Divider(),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: 'Models',
                  value: '${brand.brandModels.length} model${brand.brandModels.length != 1 ? 's' : ''}',
                ),
              ]),
            ),

            // ── Models section ────────────────────────────────────────────
            if (brand.brandModels.isNotEmpty) ...[
              const _Divider(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _SectionLabel('MODELS'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: brand.brandModels.map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kAmberBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _kAmberBd, width: 0.5),
                      ),
                      child: Text(m, style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600, color: _kAmber,
                      )),
                    )).toList(),
                  ),
                ]),
              ),
            ],
          ]),
        ),

        SizedBox(height: pad * 0.7),

        // ── Action button ─────────────────────────────────────────────────
        if (brand.brandId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('View Full Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kP, foregroundColor: _kWhite,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 10.5, fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.8,
  ));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon; final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, size: 14, color: _kT4),
      const SizedBox(width: 10),
      SizedBox(width: 90, child: Text(label, style: const TextStyle(
        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: _kT1,
      ), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String? status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _sb(status), borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _sd(status), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: _sc(status), shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(status ?? '', style: TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.w700, color: _sc(status), height: 1.0,
      )),
    ]),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _kPBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: active ? _kPBd : Colors.transparent, width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? _kP : _kT3,
      )),
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl, required this.sw, required this.sh,
    required this.hint, required this.onChanged, required this.onClear});
  final TextEditingController ctrl;
  final double sw, sh;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: (sh * 0.052).clamp(34.0, 42.0),
    child: TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _kT1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: _kT4),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kT4),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: _kT4),
            onPressed: onClear) : null,
        filled: true, fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kP, width: 1.5)),
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 0.5, color: _kBdLight);
}

// ── Empty / error states ──────────────────────────────────────────────────────
class _EmptyLeft extends StatelessWidget {
  const _EmptyLeft({required this.lw});
  final double lw;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.storefront_outlined,
          size: (lw * 0.12).clamp(32.0, 48.0), color: _kT4),
      const SizedBox(height: 10),
      Text('No brands found', style: TextStyle(
        fontSize: (lw * 0.036).clamp(12.0, 14.0),
        color: _kT3, fontWeight: FontWeight.w500)),
    ],
  ));
}

class _EmptyRight extends StatelessWidget {
  const _EmptyRight({required this.rw});
  final double rw;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _kPurpleBg, shape: BoxShape.circle,
          border: Border.all(color: _kPurpleBd, width: 0.5),
        ),
        child: const Icon(Icons.storefront_outlined, size: 26, color: _kPurple),
      ),
      const SizedBox(height: 12),
      Text('Select a brand', style: TextStyle(
        fontSize: (rw * 0.022).clamp(12.0, 15.0),
        color: _kT3, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Tap a brand on the left to see its details',
          style: TextStyle(fontSize: 11.5, color: _kT4)),
    ],
  ));
}

class _ErrView extends StatelessWidget {
  const _ErrView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 32, color: _kRed),
      const SizedBox(height: 10),
      const Text('Could not load brands',
          style: TextStyle(color: _kRed, fontWeight: FontWeight.w500)),
      const SizedBox(height: 14),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kP, foregroundColor: _kWhite,
          shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
        child: const Icon(Icons.refresh_rounded),
      ),
    ],
  ));
}
