import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/product_model.dart';
import '../../../widgets/circle_button.dart';

// ── Zoho Books design tokens (mirrored from ProductDetailsScreen) ─────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kWhite   = Colors.white;
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT2      = Color(0xFF374151);
const _kT3      = Color(0xFF6B7280);
const _kT4      = Color(0xFF9CA3AF);
const _kGreen   = Color(0xFF0F6E56);
const _kGreenBg = Color(0xFFEDFAF5);
const _kGreenBd = Color(0xFF9FE0C5);
const _kRed     = Color(0xFFDC2626);
const _kRedBg   = Color(0xFFFEF2F2);
const _kRedBd   = Color(0xFFFECACA);
const _kAmber   = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);

// ─────────────────────────────────────────────────────────────────────────────
class ProductPriceHistory extends StatelessWidget {
  final List<PriceHistory> history;
  const ProductPriceHistory({super.key, required this.history});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '—';
    return DateFormat('MMM dd, yyyy  •  HH:mm').format(date);
  }

  String _delta(double? oldP, double? newP) {
    if (oldP == null || newP == null || oldP == 0) return '';
    final pct = ((newP - oldP) / oldP * 100).abs();
    return '${pct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

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
              Text('Price History',
                  style: TextStyle(
                      fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight:   FontWeight.w700,
                      color:        _kT1,
                      letterSpacing: -0.2)),
              const Spacer(),
              // Count badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.025).clamp(8.0, 12.0),
                    vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                decoration: BoxDecoration(
                    color:        _kPBg,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(color: _kPBd, width: 0.5)),
                child: Text('${history.length}',
                    style: TextStyle(
                        fontSize:   (sw * 0.028).clamp(9.0, 12.0),
                        fontWeight: FontWeight.w700,
                        color:      _kP)),
              ),
            ]),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: history.isEmpty
                ? _EmptyState(sw: sw, sh: sh)
                : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
              itemCount: history.length,
              itemBuilder: (_, index) => _HistoryCard(
                sw:         sw,
                sh:         sh,
                entry:      history[index],
                index:      index,
                total:      history.length,
                formatDate: _formatDate,
                delta:      _delta,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _HistoryCard
// ═════════════════════════════════════════════════════════════════════════════
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.sw,
    required this.sh,
    required this.entry,
    required this.index,
    required this.total,
    required this.formatDate,
    required this.delta,
  });

  final double       sw, sh;
  final PriceHistory entry;
  final int          index, total;
  final String Function(String?)  formatDate;
  final String Function(double?, double?) delta;

  @override
  Widget build(BuildContext context) {
    final h          = entry;
    final isPriceUp  = (h.newPrice ?? 0) > (h.oldPrice ?? 0);
    final isEqual    = (h.newPrice ?? 0) == (h.oldPrice ?? 0);
    final trendColor = isEqual ? _kAmber : (isPriceUp ? _kRed  : _kGreen);
    final trendBg    = isEqual ? _kAmberBg : (isPriceUp ? _kRedBg : _kGreenBg);
    final trendBd    = isEqual ? _kAmberBd : (isPriceUp ? _kRedBd : _kGreenBd);
    final trendIcon  = isEqual
        ? Icons.trending_flat_rounded
        : (isPriceUp ? Icons.trending_up_rounded : Icons.trending_down_rounded);
    final trendLabel = isEqual ? 'No change' : (isPriceUp ? 'Increased' : 'Decreased');
    final pct        = delta(h.oldPrice!.toDouble(), h.newPrice!.toDouble());

    final oldFmt = h.oldPrice != null
        ? '₹${h.oldPrice!.toStringAsFixed(2)}'
        : '—';
    final newFmt = h.newPrice != null
        ? '₹${h.newPrice!.toStringAsFixed(2)}'
        : '—';

    return Container(
      margin: EdgeInsets.only(bottom: sh * 0.012),
      decoration: BoxDecoration(
          color:        _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border:       Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header row ──────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.032),
          child: Row(children: [
            // Index badge
            Container(
              width:  (sw * 0.075).clamp(26.0, 36.0),
              height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(
                  color:        _kPBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.022).clamp(6.0, 10.0)),
                  border:       Border.all(color: _kPBd, width: 0.5)),
              child: Center(
                child: Text('${total - index}',
                    style: TextStyle(
                        fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                        fontWeight: FontWeight.w800,
                        color:      _kP)),
              ),
            ),
            SizedBox(width: sw * 0.025),

            // Date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Price Update',
                      style: TextStyle(
                          fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                          fontWeight: FontWeight.w700,
                          color:      _kT1)),
                  SizedBox(height: sw * 0.004),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size:  (sw * 0.03).clamp(10.0, 13.0),
                        color: _kT4),
                    SizedBox(width: sw * 0.01),
                    Text(formatDate(h.changedAt),
                        style: TextStyle(
                            fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                            color:      _kT4,
                            fontWeight: FontWeight.w500)),
                  ]),
                ],
              ),
            ),

            // Trend pill
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.025).clamp(8.0, 12.0),
                  vertical:   (sw * 0.008).clamp(3.0, 5.0)),
              decoration: BoxDecoration(
                  color:        trendBg,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: trendBd, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trendIcon,
                    size:  (sw * 0.032).clamp(10.0, 14.0),
                    color: trendColor),
                SizedBox(width: sw * 0.01),
                Text(trendLabel,
                    style: TextStyle(
                        fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                        fontWeight: FontWeight.w700,
                        color:      trendColor)),
                if (pct.isNotEmpty) ...[
                  SizedBox(width: sw * 0.008),
                  Text('($pct)',
                      style: TextStyle(
                          fontSize:   (sw * 0.024).clamp(8.5, 10.5),
                          fontWeight: FontWeight.w600,
                          color:      trendColor.withValues(alpha: 0.8))),
                ],
              ]),
            ),
          ]),
        ),

        Divider(height: 1, color: _kBd),

        // ── Price comparison ─────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Row(children: [

            // Old price
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: sw * 0.035, horizontal: sw * 0.03),
                decoration: BoxDecoration(
                    color:        _kBg,
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    border:       Border.all(color: _kBd, width: 0.5)),
                child: Column(children: [
                  Text('Old Price',
                      style: TextStyle(
                          fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                          color:      _kT4,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: sw * 0.01),
                  Text(oldFmt,
                      style: TextStyle(
                          fontSize:   (sw * 0.038).clamp(13.0, 17.0),
                          fontWeight: FontWeight.w800,
                          color:      _kT3,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: _kT4)),
                ]),
              ),
            ),

            // Arrow
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.025),
              child: Container(
                padding: EdgeInsets.all((sw * 0.02).clamp(6.0, 10.0)),
                decoration: BoxDecoration(
                    color:        trendBg,
                    shape:        BoxShape.circle,
                    border:       Border.all(color: trendBd, width: 0.5)),
                child: Icon(Icons.arrow_forward_rounded,
                    color: trendColor,
                    size:  (sw * 0.04).clamp(14.0, 18.0)),
              ),
            ),

            // New price
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: sw * 0.035, horizontal: sw * 0.03),
                decoration: BoxDecoration(
                    color:        trendBg,
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    border:       Border.all(color: trendBd, width: 0.5)),
                child: Column(children: [
                  Text('New Price',
                      style: TextStyle(
                          fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                          color:      trendColor,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: sw * 0.01),
                  Text(newFmt,
                      style: TextStyle(
                          fontSize:   (sw * 0.038).clamp(13.0, 17.0),
                          fontWeight: FontWeight.w800,
                          color:      trendColor)),
                ]),
              ),
            ),
          ]),
        ),

        // ── Change reason ────────────────────────────────────────────────
        if (h.changeReason != null && h.changeReason!.trim().isNotEmpty) ...[
          Divider(height: 1, color: _kBd),
          Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.04),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width:  (sw * 0.07).clamp(24.0, 32.0),
                height: (sw * 0.07).clamp(24.0, 32.0),
                decoration: BoxDecoration(
                    color:        _kBg,
                    borderRadius: BorderRadius.circular(
                        (sw * 0.018).clamp(5.0, 8.0)),
                    border:       Border.all(color: _kBd, width: 0.5)),
                child: Icon(Icons.notes_outlined,
                    size:  (sw * 0.036).clamp(12.0, 16.0),
                    color: _kT4),
              ),
              SizedBox(width: sw * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reason',
                        style: TextStyle(
                            fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                            fontWeight: FontWeight.w700,
                            color:      _kT4,
                            letterSpacing: 0.3)),
                    SizedBox(height: sw * 0.006),
                    Text(h.changeReason!,
                        style: TextStyle(
                            fontSize:   (sw * 0.032).clamp(11.0, 14.0),
                            color:      _kT2,
                            fontWeight: FontWeight.w500,
                            height:     1.4)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ]),
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
        width:  (sw * 0.2).clamp(70.0, 100.0),
        height: (sw * 0.2).clamp(70.0, 100.0),
        decoration: BoxDecoration(
            color:  _kWhite,
            shape:  BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.receipt_long_outlined,
            size:  (sw * 0.1).clamp(34.0, 50.0), color: _kT4),
      ),
      SizedBox(height: sh * 0.02),
      Text('No Price History',
          style: TextStyle(
              fontSize:   (sw * 0.04).clamp(13.0, 18.0),
              fontWeight: FontWeight.w700,
              color:      _kT2)),
      SizedBox(height: sh * 0.006),
      Text('Price changes will appear here',
          style: TextStyle(
              fontSize: (sw * 0.032).clamp(11.0, 14.0),
              color:    _kT4)),
    ]),
  );
}