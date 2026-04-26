import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/order_model.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue        = Color(0xFF1B4FD8);
const _kBlueBg      = Color(0xFFEEF2FF);
const _kBlueBorder  = Color(0xFFC7D4FF);
const _kBg          = Color(0xFFF2F4F8);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFE5E7EB);
const _kDark        = Color(0xFF111827);
const _kMid         = Color(0xFF374151);
const _kMuted       = Color(0xFF9CA3AF);
const _kGreen       = Color(0xFF0A8A5C);
const _kGreenBg     = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kAmber       = Color(0xFFB45309);
const _kAmberBg     = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);

// ─── Parsed payment entry ─────────────────────────────────────────────────────
class _PaymentEntry {
  final num amount;
  final String method;
  final String rawDate;
  final String raw;

  const _PaymentEntry({
    required this.amount,
    required this.method,
    required this.rawDate,
    required this.raw,
  });

  static _PaymentEntry? tryParse(String note) {
    try {
      final amountMatch = RegExp(r'[\d,]+').firstMatch(note.replaceAll('💰', '').trim());
      if (amountMatch == null) return null;
      final amount = num.tryParse(amountMatch.group(0)!.replaceAll(',', ''));
      if (amount == null) return null;
      final viaMatch = RegExp(r'via\s+(\w+)', caseSensitive: false).firstMatch(note);
      final method = viaMatch?.group(1)?.toUpperCase() ?? 'N/A';
      final onMatch = RegExp(r'on\s+(.+)$', caseSensitive: false).firstMatch(note);
      final rawDate = onMatch?.group(1)?.trim() ?? '';
      return _PaymentEntry(amount: amount, method: method, rawDate: rawDate, raw: note);
    } catch (_) {
      return null;
    }
  }

  Color get methodColor  => method == 'BANK' ? _kBlue  : _kGreen;
  Color get methodBg     => method == 'BANK' ? _kBlueBg  : _kGreenBg;
  Color get methodBorder => method == 'BANK' ? _kBlueBorder : _kGreenBorder;
  IconData get methodIcon =>
      method == 'BANK' ? Icons.account_balance_outlined : Icons.payments_outlined;
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class PaymentHistoryPage extends StatelessWidget {
  final OrderModel order;
  const PaymentHistoryPage({super.key, required this.order});

  // ── Payment status helpers ──────────────────────────────────────────────
  Color _paymentStatusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreen;
      case 'PARTIAL':
      case 'PENDING': return _kAmber;
      default:        return _kMuted;
    }
  }

  Color _paymentStatusBg(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreenBg;
      case 'PARTIAL':
      case 'PENDING': return _kAmberBg;
      default:        return _kBg;
    }
  }

  Color _paymentStatusBorder(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreenBorder;
      case 'PARTIAL':
      case 'PENDING': return _kAmberBorder;
      default:        return _kBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final entries = (order.paymentNotes ?? [])
        .map((n) => _PaymentEntry.tryParse(n.toString()))
        .whereType<_PaymentEntry>()
        .toList()
        .reversed
        .toList();

    final totalPaid = order.amountPaid;
    final totalDue  = order.amountDue ?? 0;
    final cashTotal = entries
        .where((e) => e.method == 'CASH')
        .fold<num>(0, (s, e) => s + e.amount);
    final bankTotal = entries
        .where((e) => e.method == 'BANK')
        .fold<num>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top nav ───────────────────────────────────────────────────────
          Container(
            color: _kCard,
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
            child: Row(children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width:  (sw * 0.1).clamp(36.0, 48.0),
                  height: (sw * 0.1).clamp(36.0, 48.0),
                  decoration: BoxDecoration(
                    color: _kCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Icon(Icons.arrow_back_ios_rounded,
                      size: (sw * 0.04).clamp(14.0, 20.0), color: _kDark),
                ),
              ),
              SizedBox(width: sw * 0.03),

              // Title + order number
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment History', style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                      letterSpacing: -0.2)),
                  Text(order.orderNumber ?? '', style: TextStyle(
                      fontSize: (sw * 0.028).clamp(9.5, 13.0),
                      color: _kMuted,
                      fontWeight: FontWeight.w500)),
                ],
              )),

              // Payment status badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.03).clamp(10.0, 14.0),
                    vertical:   (sw * 0.012).clamp(4.0, 7.0)),
                decoration: BoxDecoration(
                  color: _paymentStatusBg(order.paymentStatus),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _paymentStatusBorder(order.paymentStatus),
                      width: 1.5),
                ),
                child: Text(order.paymentStatus ?? 'N/A', style: TextStyle(
                    fontSize: (sw * 0.028).clamp(9.5, 13.0),
                    fontWeight: FontWeight.w700,
                    color: _paymentStatusColor(order.paymentStatus))),
              ),
            ]),
          ),

          // ── Scrollable body ───────────────────────────────────────────────
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
            child: Column(children: [
              SizedBox(height: sh * 0.012),

              // ── Summary cards ──────────────────────────────────────────
              Row(children: [
                Expanded(child: _SummaryCard(
                  sw: sw,
                  label: 'Total Paid',
                  amount: totalPaid,
                  color: _kGreen,
                  bg: _kGreenBg,
                  border: _kGreenBorder,
                  icon: Icons.check_circle_outline_rounded,
                )),
                SizedBox(width: sw * 0.03),
                Expanded(child: _SummaryCard(
                  sw: sw,
                  label: 'Amount Due',
                  amount: totalDue,
                  color:  totalDue > 0 ? _kAmber : _kGreen,
                  bg:     totalDue > 0 ? _kAmberBg : _kGreenBg,
                  border: totalDue > 0 ? _kAmberBorder : _kGreenBorder,
                  icon:   totalDue > 0
                      ? Icons.pending_outlined
                      : Icons.task_alt_rounded,
                )),
              ]),
              SizedBox(height: sh * 0.015),

              // ── Method breakdown ───────────────────────────────────────
              if (cashTotal > 0 || bankTotal > 0) ...[
                Container(
                  padding: EdgeInsets.all((sw * 0.04).clamp(12.0, 20.0)),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                    border: Border.all(color: _kBorder, width: 0.5),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    if (cashTotal > 0)
                      Expanded(child: _MethodBreakdown(
                        sw: sw,
                        label: 'Cash',
                        amount: cashTotal,
                        icon: Icons.payments_outlined,
                        color: _kGreen,
                        bg: _kGreenBg,
                        border: _kGreenBorder,
                      )),
                    if (cashTotal > 0 && bankTotal > 0)
                      Container(
                          width: 1,
                          height: (sw * 0.12).clamp(40.0, 60.0),
                          color: _kBorder,
                          margin: EdgeInsets.symmetric(
                              horizontal: (sw * 0.03).clamp(10.0, 16.0))),
                    if (bankTotal > 0)
                      Expanded(child: _MethodBreakdown(
                        sw: sw,
                        label: 'Bank',
                        amount: bankTotal,
                        icon: Icons.account_balance_outlined,
                        color: _kBlue,
                        bg: _kBlueBg,
                        border: _kBlueBorder,
                      )),
                  ]),
                ),
                SizedBox(height: sh * 0.015),
              ],

              // ── Transactions list ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                  border: Border.all(color: _kBorder, width: 0.5),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(children: [
                  // Section header
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04,
                        vertical:   sw * 0.035),
                    child: Row(children: [
                      Container(
                        width:  (sw * 0.075).clamp(26.0, 36.0),
                        height: (sw * 0.075).clamp(26.0, 36.0),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.022).clamp(6.0, 10.0)),
                          border: Border.all(color: _kBlueBorder, width: 0.5),
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            size: (sw * 0.04).clamp(14.0, 20.0), color: _kBlue),
                      ),
                      SizedBox(width: sw * 0.025),
                      Expanded(child: Text('Transactions', style: TextStyle(
                          fontSize: (sw * 0.035).clamp(12.0, 16.0),
                          fontWeight: FontWeight.w700,
                          color: _kDark))),
                      // Count badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: (sw * 0.025).clamp(8.0, 12.0),
                            vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlueBorder, width: 0.5),
                        ),
                        child: Text('${entries.length}', style: TextStyle(
                            fontSize: (sw * 0.026).clamp(9.0, 12.0),
                            fontWeight: FontWeight.w700,
                            color: _kBlue)),
                      ),
                    ]),
                  ),
                  const Divider(height: 1, color: _kBorder),

                  // Empty state
                  if (entries.isEmpty)
                    Padding(
                      padding: EdgeInsets.all((sw * 0.08).clamp(24.0, 48.0)),
                      child: Column(children: [
                        Icon(Icons.receipt_outlined,
                            size: (sw * 0.12).clamp(40.0, 60.0), color: _kMuted),
                        SizedBox(height: sw * 0.03),
                        Text('No payment records', style: TextStyle(
                            fontSize: (sw * 0.035).clamp(12.0, 16.0),
                            color: _kMuted,
                            fontWeight: FontWeight.w500)),
                      ]),
                    ),

                  // Entry rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: _kBorder),
                    itemBuilder: (_, i) => _TransactionRow(
                      sw: sw, sh: sh,
                      entry: entries[i],
                      index: i,
                      total: entries.length,
                    ),
                  ),
                ]),
              ),

              SizedBox(height: sh * 0.04),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final double sw;
  final String label;
  final num amount;
  final Color color, bg, border;
  final IconData icon;

  const _SummaryCard({
    required this.sw,
    required this.label,
    required this.amount,
    required this.color,
    required this.bg,
    required this.border,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all((sw * 0.04).clamp(12.0, 20.0)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: border, width: 0.5),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: (sw * 0.04).clamp(14.0, 20.0), color: color),
          SizedBox(width: sw * 0.015),
          Flexible(child: Text(label, style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 13.0),
              color: color,
              fontWeight: FontWeight.w600))),
        ]),
        SizedBox(height: sw * 0.02),
        Text(
          '₹${NumberFormat('#,##,###').format(amount)}',
          style: TextStyle(
              fontSize: (sw * 0.044).clamp(15.0, 22.0),
              fontWeight: FontWeight.w800,
              color: color),
        ),
      ]),
    );
  }
}

// ─── Method breakdown ─────────────────────────────────────────────────────────
class _MethodBreakdown extends StatelessWidget {
  final double sw;
  final String label;
  final num amount;
  final IconData icon;
  final Color color, bg, border;

  const _MethodBreakdown({
    required this.sw,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: EdgeInsets.all((sw * 0.03).clamp(10.0, 16.0)),
        decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 0.5)),
        child: Icon(icon,
            size: (sw * 0.05).clamp(18.0, 26.0), color: color),
      ),
      SizedBox(height: sw * 0.015),
      Text(label, style: TextStyle(
          fontSize: (sw * 0.028).clamp(9.5, 13.0),
          color: _kMuted,
          fontWeight: FontWeight.w500)),
      SizedBox(height: sw * 0.005),
      Text('₹${NumberFormat('#,##,###').format(amount)}',
          style: TextStyle(
              fontSize: (sw * 0.036).clamp(12.0, 18.0),
              fontWeight: FontWeight.w800,
              color: color)),
    ]);
  }
}

// ─── Transaction row ──────────────────────────────────────────────────────────
class _TransactionRow extends StatelessWidget {
  final double sw, sh;
  final _PaymentEntry entry;
  final int index, total;

  const _TransactionRow({
    required this.sw,
    required this.sh,
    required this.entry,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          sw * 0.04,
          sw * 0.035,
          sw * 0.04,
          isLast ? sw * 0.035 : sw * 0.02),
      child: Row(children: [
        // Method icon badge
        Container(
          width:  (sw * 0.11).clamp(38.0, 52.0),
          height: (sw * 0.11).clamp(38.0, 52.0),
          decoration: BoxDecoration(
            color: entry.methodBg,
            borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
            border: Border.all(color: entry.methodBorder, width: 0.5),
          ),
          child: Icon(entry.methodIcon,
              size: (sw * 0.05).clamp(18.0, 26.0), color: entry.methodColor),
        ),
        SizedBox(width: sw * 0.03),

        // Details
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              // Method chip
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.02).clamp(6.0, 10.0),
                    vertical:   (sw * 0.006).clamp(2.0, 4.0)),
                decoration: BoxDecoration(
                  color: entry.methodBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: entry.methodBorder, width: 0.5),
                ),
                child: Text(entry.method, style: TextStyle(
                    fontSize: (sw * 0.024).clamp(8.5, 11.5),
                    fontWeight: FontWeight.w700,
                    color: entry.methodColor)),
              ),
              SizedBox(width: sw * 0.015),
              Text('#${total - index}', style: TextStyle(
                  fontSize: (sw * 0.026).clamp(9.0, 12.0),
                  color: _kMuted,
                  fontWeight: FontWeight.w500)),
            ]),
            SizedBox(height: sw * 0.01),
            // Date
            Row(children: [
              Icon(Icons.access_time_rounded,
                  size: (sw * 0.028).clamp(9.5, 13.0), color: _kMuted),
              SizedBox(width: sw * 0.008),
              Expanded(child: Text(entry.rawDate,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: (sw * 0.027).clamp(9.0, 12.5),
                      color: _kMuted,
                      fontWeight: FontWeight.w500))),
            ]),
          ],
        )),

        // Amount
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '₹${NumberFormat('#,##,###').format(entry.amount)}',
            style: TextStyle(
                fontSize: (sw * 0.038).clamp(13.0, 19.0),
                fontWeight: FontWeight.w800,
                color: _kDark),
          ),
          SizedBox(height: sw * 0.005),
          Text('received', style: TextStyle(
              fontSize: (sw * 0.025).clamp(8.5, 11.5),
              color: _kGreen,
              fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }
}