import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/order_model.dart';

const _kIndigo  = Color(0xFF4F46E5); // indigo 600 — in-progress
const _kEmerald = Color(0xFF059669); // emerald 600 — complete
const _kTrack   = Color(0xFFEEF1F4); // bar track
const _kT3      = Color(0xFF9CA3AF);

String _fmt(int n) => NumberFormat('#,##,###').format(n);

/// Compact progress indicator for an order — thin bar driven by
/// `delivered_percent` plus a one-line caption like "13/22 delivered · 59%".
///
/// Use [OrderProgressBar.maybeFor] from list cards — it returns `null` when
/// the bar wouldn't add information.
class OrderProgressBar extends StatelessWidget {
  final OrderProgress progress;
  final double sw;
  final double sh;

  const OrderProgressBar({
    super.key,
    required this.progress,
    required this.sw,
    required this.sh,
  });

  /// Returns the widget only when it adds information. Hides itself when:
  ///   - progress is null (older endpoints / stale data), or
  ///   - the order was cancelled or rejected (already evident from status), or
  ///   - the order has no line items (qty_ordered_total <= 0).
  /// Otherwise shows — even at 0% delivered, an empty bar signals
  /// "nothing delivered yet" which is useful.
  static Widget? maybeFor({
    Key? key,
    required OrderProgress? progress,
    required String? status,
    required double sw,
    required double sh,
  }) {
    if (progress == null) return null;
    if (progress.qtyOrderedTotal <= 0) return null;
    final s = (status ?? '').toUpperCase();
    if (s == 'CANCELLED' || s == 'REJECTED') return null;
    return OrderProgressBar(
      key: key, progress: progress, sw: sw, sh: sh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final pct = p.deliveredPercent.clamp(0, 100);
    final complete = p.qtyDeliveredTotal >= p.qtyOrderedTotal;
    final fill = complete ? _kEmerald : _kIndigo;
    final height = (sh * 0.005).clamp(3.0, 4.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caption above bar — keeps numbers readable even if the bar shrinks.
        Text(
          '${_fmt(p.qtyDeliveredTotal)}/${_fmt(p.qtyOrderedTotal)} delivered · $pct%',
          style: TextStyle(
            fontSize: (sw * 0.026).clamp(9.0, 11.0),
            color: _kT3, fontWeight: FontWeight.w500,
            letterSpacing: 0.1, height: 1.2,
          ),
          textAlign: TextAlign.start,
          maxLines: 1, overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: sh * 0.005),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth;
              final filledW = (w * (pct / 100.0)).clamp(0.0, w);
              return Stack(children: [
                Container(width: w, color: _kTrack),
                Container(width: filledW, color: fill),
              ]);
            }),
          ),
        ),
      ],
    );
  }
}
