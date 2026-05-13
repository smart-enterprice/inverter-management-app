// lib/feature/signup/screen/dealer/tablet/dealers_tablet_view.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../feature/signup/model/user_model.dart';
import '../../../../../feature/signup/controller/signUp_controller.dart';
import '../../../../../widgets/circle_button.dart';
import '../dealer_view_screen.dart';

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
const _kRed      = Color(0xFFDC2626);

const _avatarSets = [
  (Color(0xFFEBF4FF), Color(0xFFBFD9F5), Color(0xFF185FA5)),
  (Color(0xFFEDFAF5), Color(0xFF9FE0C5), Color(0xFF0F6E56)),
  (Color(0xFFF5F3FF), Color(0xFFDDD6FE), Color(0xFF7C3AED)),
  (Color(0xFFFFFBEB), Color(0xFFFCD28A), Color(0xFFB45309)),
  (Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)),
];

(Color, Color, Color) _avatarColors(int i) => _avatarSets[i % _avatarSets.length];

String _initials(String name) => name.trim().split(' ').take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

// ═════════════════════════════════════════════════════════════════════════════
class DealersTabletView extends ConsumerStatefulWidget {
  const DealersTabletView({super.key});
  @override
  ConsumerState<DealersTabletView> createState() => _State();
}

class _State extends ConsumerState<DealersTabletView> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  UserModel? _sel;
  int        _selIdx = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(dealerListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final lw = (sw * 0.38).clamp(260.0, 420.0);

    final dealersAsync  = ref.watch(dealerListProvider);
    final isFiltering   = ref.watch(dealerFilteringProvider);
    final isLoadingMore = ref.watch(dealerLoadingMoreProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────────
          _TopBar(
            sw: sw, sh: sh, ctrl: _ctrl,
            onChanged: (v) {
              ref.read(dealerListProvider.notifier).searchDealers(v);
            },
            onClear: () {
              _ctrl.clear();
              ref.read(dealerListProvider.notifier).searchDealers('');
            },
            onRefresh: () => ref.read(dealerListProvider.notifier).refresh(),
          ),

          // ── Split view ───────────────────────────────────────────────────
          Expanded(child: dealersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
            error: (_, __) => _ErrView(
                onRetry: () => ref.read(dealerListProvider.notifier).refresh()),
            data: (dealers) {
              final hasMore = ref.read(dealerListProvider.notifier).hasMore;
              if (_sel == null && dealers.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _sel == null) {
                    setState(() { _sel = dealers.first; _selIdx = 0; });
                  }
                });
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // LEFT — dealer list
                SizedBox(
                  width: lw,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    child: Stack(children: [
                      dealers.isEmpty
                          ? _EmptyLeft(lw: lw)
                          : ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.only(top: sh * 0.008),
                        itemCount: dealers.length + (hasMore || isLoadingMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i >= dealers.length) {
                            return isLoadingMore
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Center(child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: _kP, strokeWidth: 2),
                              )),
                            )
                                : const SizedBox.shrink();
                          }
                          final d = dealers[i];
                          final c = _avatarColors(i);
                          return _DealerRow(
                            dealer:   d,
                            selected: _sel?.employeeId == d.employeeId,
                            lw: lw,
                            avatarBg: c.$1, avatarBd: c.$2, avatarFg: c.$3,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() { _sel = d; _selIdx = i; });
                            },
                          );
                        },
                      ),
                      if (isFiltering)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.7)),
                              child: const Center(child: SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: _kP, strokeWidth: 2),
                              )),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),

                // RIGHT — detail
                Expanded(
                  child: _sel == null
                      ? _EmptyRight(rw: sw - lw)
                      : _DetailCard(
                    dealer: _sel!, index: _selIdx,
                    rw: sw - lw, sh: sh,
                    onOpen: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            DealerView(dealerId: _sel!.employeeId!))),
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
    required this.onChanged, required this.onClear, required this.onRefresh});
  final double sw, sh;
  final TextEditingController ctrl;
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
      Text('Dealers', style: TextStyle(
        fontSize: (sw * 0.022).clamp(16.0, 20.0),
        fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3,
      )),
      SizedBox(width: sw * 0.02),
      Expanded(child: _SearchField(ctrl: ctrl, sw: sw, sh: sh,
          hint: 'Search by name, phone or location…',
          onChanged: onChanged, onClear: onClear)),
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

// ── Dealer list row ───────────────────────────────────────────────────────────
class _DealerRow extends StatelessWidget {
  const _DealerRow({required this.dealer, required this.selected, required this.lw,
    required this.avatarBg, required this.avatarBd, required this.avatarFg,
    required this.onTap});
  final UserModel dealer;
  final bool selected;
  final double lw;
  final Color avatarBg, avatarBd, avatarFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = dealer.photo != null && dealer.photo!.isNotEmpty;
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
          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBg,
              border: Border.all(color: avatarBd, width: 1.0),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                imageUrl: dealer.photo!, fit: BoxFit.cover,
                placeholder: (_, __) => _Initials(
                    name: dealer.employeeName, bg: avatarBg, fg: avatarFg),
                errorWidget: (_, __, ___) => _Initials(
                    name: dealer.employeeName, bg: avatarBg, fg: avatarFg),
              )
                  : _Initials(name: dealer.employeeName, bg: avatarBg, fg: avatarFg),
            ),
          ),
          SizedBox(width: lw * 0.04),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(dealer.employeeName.replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: (lw * 0.042).clamp(12.0, 14.0),
                  fontWeight: FontWeight.w700,
                  color: selected ? _kP : _kT1,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(dealer.town ?? dealer.employeePhone,
                style: TextStyle(
                  fontSize: (lw * 0.032).clamp(9.5, 11.0),
                  color: _kT4, fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.bg, required this.fg});
  final String name; final Color bg, fg;
  @override
  Widget build(BuildContext context) => Container(
    color: bg,
    child: Center(child: Text(_initials(name), style: TextStyle(
      fontSize: 13, fontWeight: FontWeight.w800, color: fg,
    ))),
  );
}

// ── Detail card ───────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.dealer, required this.index,
    required this.rw, required this.sh, required this.onOpen});
  final UserModel dealer;
  final int index;
  final double rw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pad = (rw * 0.06).clamp(18.0, 32.0);
    final c   = _avatarColors(index);
    final hasPhoto = dealer.photo != null && dealer.photo!.isNotEmpty;

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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: c.$1,
                    border: Border.all(color: c.$2, width: 1.5),
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? CachedNetworkImage(
                      imageUrl: dealer.photo!, fit: BoxFit.cover,
                      placeholder: (_, __) => _Initials(
                          name: dealer.employeeName, bg: c.$1, fg: c.$3),
                      errorWidget: (_, __, ___) => _Initials(
                          name: dealer.employeeName, bg: c.$1, fg: c.$3),
                    )
                        : _Initials(name: dealer.employeeName, bg: c.$1, fg: c.$3),
                  ),
                ),
                SizedBox(width: pad * 0.6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dealer.employeeName.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: (rw * 0.032).clamp(15.0, 20.0),
                        fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.2,
                      ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if ((dealer.shopName ?? '').isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(dealer.shopName!, style: const TextStyle(
                        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ])),
              ]),
            ),

            // ── Contact section ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionLabel('CONTACT INFORMATION'),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.phone_outlined,
                    label: 'Phone', value: dealer.employeePhone),
                const _Divider(),
                _InfoRow(icon: Icons.email_outlined,
                    label: 'Email', value: dealer.employeeEmail),
              ]),
            ),

            // ── Location section ──────────────────────────────────────────
            if (dealer.address.isNotEmpty ||
                dealer.town != null || dealer.district != null) ...[
              const _Divider(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _SectionLabel('LOCATION'),
                  const SizedBox(height: 8),
                  if (dealer.address.isNotEmpty) ...[
                    _InfoRow(icon: Icons.location_on_outlined,
                        label: 'Address', value: dealer.address),
                    if (dealer.town != null || dealer.district != null)
                      const _Divider(),
                  ],
                  if (dealer.town != null) ...[
                    _InfoRow(icon: Icons.location_city_outlined,
                        label: 'Town', value: dealer.town!),
                    if (dealer.district != null) const _Divider(),
                  ],
                  if (dealer.district != null)
                    _InfoRow(icon: Icons.map_outlined,
                        label: 'District', value: dealer.district!),
                ]),
              ),
            ],
          ]),
        ),

        SizedBox(height: pad * 0.7),

        // ── Action button ─────────────────────────────────────────────────
        if (dealer.employeeId != null)
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
      SizedBox(width: 72, child: Text(label, style: const TextStyle(
        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600, color: _kT1,
      ), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
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
      Icon(Icons.people_outline_rounded,
          size: (lw * 0.12).clamp(32.0, 48.0), color: _kT4),
      const SizedBox(height: 10),
      Text('No dealers found', style: TextStyle(
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
          color: _kPBg, shape: BoxShape.circle,
          border: Border.all(color: _kPBd, width: 0.5),
        ),
        child: const Icon(Icons.people_outline_rounded, size: 26, color: _kP),
      ),
      const SizedBox(height: 12),
      Text('Select a dealer', style: TextStyle(
        fontSize: (rw * 0.022).clamp(12.0, 15.0),
        color: _kT3, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Tap a dealer on the left to see their details',
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
      const Text('Could not load dealers',
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
