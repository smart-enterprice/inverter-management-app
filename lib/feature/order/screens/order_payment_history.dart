import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/media_query/media_query.dart';
import '../../../feature/order/model/order_model.dart';
import '../../../widgets/circle_button.dart';

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
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);

// ── Parsed payment entry ──────────────────────────────────────────────────────
class _PaymentEntry {
  final num    amount;
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
      final amountMatch = RegExp(r'[\d,]+')
          .firstMatch(note.replaceAll('💰', '').trim());
      if (amountMatch == null) return null;
      final amount =
      num.tryParse(amountMatch.group(0)!.replaceAll(',', ''));
      if (amount == null) return null;
      final viaMatch =
      RegExp(r'via\s+(\w+)', caseSensitive: false).firstMatch(note);
      final method = viaMatch?.group(1)?.toUpperCase() ?? 'N/A';
      final onMatch =
      RegExp(r'on\s+(.+)$', caseSensitive: false).firstMatch(note);
      final rawDate = onMatch?.group(1)?.trim() ?? '';
      return _PaymentEntry(
          amount: amount, method: method, rawDate: rawDate, raw: note);
    } catch (_) {
      return null;
    }
  }

  Color    get methodColor => method == 'BANK' ? _kP      : _kGreen;
  Color    get methodBg    => method == 'BANK' ? _kPBg    : _kGreenBg;
  Color    get methodBd    => method == 'BANK' ? _kPBd    : _kGreenBd;
  IconData get methodIcon  => method == 'BANK'
      ? Icons.account_balance_outlined
      : Icons.payments_outlined;
}

// ─────────────────────────────────────────────────────────────────────────────
class PaymentHistoryPage extends StatelessWidget {
  final OrderModel order;
  const PaymentHistoryPage({super.key, required this.order});

  Color _statusColor(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreen;
      case 'PARTIAL':
      case 'PENDING': return _kAmber;
      default:        return _kT4;
    }
  }

  Color _statusBg(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreenBg;
      case 'PARTIAL':
      case 'PENDING': return _kAmberBg;
      default:        return _kBg;
    }
  }

  Color _statusBd(String? s) {
    switch (s?.toUpperCase()) {
      case 'PAID':    return _kGreenBd;
      case 'PARTIAL':
      case 'PENDING': return _kAmberBd;
      default:        return _kBd;
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

    final totalPaid = order.amountPaid ?? 0;
    final totalDue  = order.amountDue  ?? 0;
    final cashTotal = entries
        .where((e) => e.method == 'CASH')
        .fold<num>(0, (s, e) => s + e.amount);
    final bankTotal = entries
        .where((e) => e.method == 'BANK')
        .fold<num>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [

        // ── App Bar ──────────────────────────────────────────────────
        Container(
          color:   _kWhite,
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context)),
            const Spacer(),
            Column(children: [
              Text('Payment History',
                  style: TextStyle(
                      fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight:   FontWeight.w700,
                      color:        _kT1,
                      letterSpacing: -0.2)),
              if ((order.orderNumber ?? '').isNotEmpty)
                Text(order.orderNumber!,
                    style: TextStyle(
                        fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                        color:      _kT4,
                        fontWeight: FontWeight.w500)),
            ]),
            const Spacer(),
            // Status pill
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.025).clamp(8.0, 12.0),
                  vertical:   (sw * 0.008).clamp(3.0, 5.0)),
              decoration: BoxDecoration(
                  color:        _statusBg(order.paymentStatus),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusBd(order.paymentStatus), width: 0.5)),
              child: Text(order.paymentStatus ?? 'N/A',
                  style: TextStyle(
                      fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                      fontWeight: FontWeight.w700,
                      color:      _statusColor(order.paymentStatus))),
            ),
          ]),
        ),

        // ── Scrollable body ──────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
            child: Column(children: [

              // ── Summary ──────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: _SummaryCard(
                    sw: sw, label: 'Total Paid', amount: totalPaid,
                    color: _kGreen, bg: _kGreenBg, bd: _kGreenBd,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: _SummaryCard(
                    sw: sw, label: 'Amount Due', amount: totalDue,
                    color: totalDue > 0 ? _kAmber : _kGreen,
                    bg:    totalDue > 0 ? _kAmberBg : _kGreenBg,
                    bd:    totalDue > 0 ? _kAmberBd : _kGreenBd,
                    icon:  totalDue > 0
                        ? Icons.pending_outlined
                        : Icons.task_alt_rounded,
                  ),
                ),
              ]),
              SizedBox(height: sh * 0.012),

              // ── Method breakdown ────────────────────────────────
              if (cashTotal > 0 || bankTotal > 0) ...[
                _Sec(
                  sw: sw,
                  icon: Icons.bar_chart_rounded,
                  iconBg: _kBg, iconColor: _kT1,
                  title: 'Breakdown by Method',
                  child: Row(children: [
                    if (cashTotal > 0)
                      Expanded(
                        child: _MethodBreakdown(
                          sw: sw, label: 'Cash', amount: cashTotal,
                          icon: Icons.payments_outlined,
                          color: _kGreen, bg: _kGreenBg, bd: _kGreenBd,
                        ),
                      ),
                    if (cashTotal > 0 && bankTotal > 0)
                      Container(
                          width: 1, height: sw * 0.14, color: _kBd,
                          margin: EdgeInsets.symmetric(
                              horizontal: sw * 0.03)),
                    if (bankTotal > 0)
                      Expanded(
                        child: _MethodBreakdown(
                          sw: sw, label: 'Bank', amount: bankTotal,
                          icon: Icons.account_balance_outlined,
                          color: _kP, bg: _kPBg, bd: _kPBd,
                        ),
                      ),
                  ]),
                ),
                SizedBox(height: sh * 0.012),
              ],

              // ── Transactions ────────────────────────────────────
              _Sec(
                sw: sw,
                icon: Icons.receipt_long_rounded,
                iconBg: _kPBg, iconColor: _kP,
                title: 'Transactions',
                trailing: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.025).clamp(8.0, 12.0),
                      vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                  decoration: BoxDecoration(
                      color:        _kPBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kPBd, width: 0.5)),
                  child: Text('${entries.length}',
                      style: TextStyle(
                          fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                          fontWeight: FontWeight.w700,
                          color:      _kP)),
                ),
                child: entries.isEmpty
                    ? _EmptyTransactions(sw: sw, sh: sh)
                    : Column(
                  children: entries.asMap().entries.map((e) {
                    final isLast =
                        e.key == entries.length - 1;
                    return Column(children: [
                      _TransactionRow(
                        sw:    sw,
                        sh:    sh,
                        entry: e.value,
                        index: e.key,
                        total: entries.length,
                      ),
                      if (!isLast) Divider(height: 1, color: _kBd),
                    ]);
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ])),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _Sec — section card identical to the rest of the app
// ═════════════════════════════════════════════════════════════════════════════
class _Sec extends StatelessWidget {
  const _Sec({
    required this.sw,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });
  final double   sw;
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   title;
  final Widget   child;
  final Widget?  trailing;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            Container(
              width:  (sw * 0.075).clamp(26.0, 36.0),
              height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.022).clamp(6.0, 10.0)),
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(icon,
                  size:  (sw * 0.04).clamp(14.0, 20.0),
                  color: iconColor),
            ),
            SizedBox(width: sw * 0.025),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize:   (sw * 0.035).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w700,
                      color:      _kT1)),
            ),
            if (trailing != null) trailing!,
          ]),
        ),
        Divider(height: 1, color: _kBd),
        Padding(
            padding: EdgeInsets.all(sw * 0.04), child: child),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _SummaryCard
// ═════════════════════════════════════════════════════════════════════════════
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.sw,
    required this.label,
    required this.amount,
    required this.color,
    required this.bg,
    required this.bd,
    required this.icon,
  });
  final double sw; final String label; final num amount;
  final Color color, bg, bd; final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(sw * 0.04),
    decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: bd, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon,
            size:  (sw * 0.034).clamp(11.5, 15.0), color: color),
        SizedBox(width: sw * 0.012),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                  color:      color,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
      SizedBox(height: sw * 0.018),
      Text(
        '₹${NumberFormat('#,##,###').format(amount)}',
        style: TextStyle(
            fontSize:   (sw * 0.042).clamp(14.0, 20.0),
            fontWeight: FontWeight.w900,
            color:      color),
      ),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _MethodBreakdown
// ═════════════════════════════════════════════════════════════════════════════
class _MethodBreakdown extends StatelessWidget {
  const _MethodBreakdown({
    required this.sw,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bg,
    required this.bd,
  });
  final double sw; final String label; final num amount;
  final IconData icon; final Color color, bg, bd;

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      padding: EdgeInsets.all((sw * 0.03).clamp(10.0, 16.0)),
      decoration: BoxDecoration(
          color:  bg, shape: BoxShape.circle,
          border: Border.all(color: bd, width: 0.5)),
      child: Icon(icon,
          size:  (sw * 0.048).clamp(16.0, 22.0), color: color),
    ),
    SizedBox(height: sw * 0.015),
    Text(label,
        style: TextStyle(
            fontSize:   (sw * 0.028).clamp(9.5, 12.5),
            color:      _kT4,
            fontWeight: FontWeight.w500)),
    SizedBox(height: sw * 0.006),
    Text('₹${NumberFormat('#,##,###').format(amount)}',
        style: TextStyle(
            fontSize:   (sw * 0.036).clamp(12.0, 16.0),
            fontWeight: FontWeight.w800,
            color:      color)),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// _EmptyTransactions
// ═════════════════════════════════════════════════════════════════════════════
class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      width:  (sw * 0.18).clamp(60.0, 90.0),
      height: (sw * 0.18).clamp(60.0, 90.0),
      decoration: BoxDecoration(
          color:  _kBg, shape: BoxShape.circle,
          border: Border.all(color: _kBd, width: 0.5)),
      child: Icon(Icons.receipt_outlined,
          size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
    ),
    SizedBox(height: sh * 0.02),
    Text('No payment records',
        style: TextStyle(
            fontSize:   (sw * 0.034).clamp(11.5, 15.0),
            fontWeight: FontWeight.w600,
            color:      _kT2)),
    SizedBox(height: sh * 0.006),
    Text('Payments will appear here once recorded',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: (sw * 0.029).clamp(10.0, 13.0), color: _kT4)),
  ]);
}

// ═════════════════════════════════════════════════════════════════════════════
// _TransactionRow
// ═════════════════════════════════════════════════════════════════════════════
class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.sw,
    required this.sh,
    required this.entry,
    required this.index,
    required this.total,
  });
  final double sw, sh; final _PaymentEntry entry;
  final int index, total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(sw * 0.04),
    child: Row(children: [

      // Method icon badge
      Container(
        width:  (sw * 0.1).clamp(36.0, 48.0),
        height: (sw * 0.1).clamp(36.0, 48.0),
        decoration: BoxDecoration(
            color:        entry.methodBg,
            borderRadius: BorderRadius.circular(
                (sw * 0.028).clamp(8.0, 12.0)),
            border: Border.all(color: entry.methodBd, width: 0.5)),
        child: Icon(entry.methodIcon,
            size:  (sw * 0.048).clamp(16.0, 22.0),
            color: entry.methodColor),
      ),
      SizedBox(width: sw * 0.03),

      // Details
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Method pill
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.02).clamp(6.0, 10.0),
                  vertical:   (sw * 0.006).clamp(2.0, 4.5)),
              decoration: BoxDecoration(
                  color:        entry.methodBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: entry.methodBd, width: 0.5)),
              child: Text(entry.method,
                  style: TextStyle(
                      fontSize:   (sw * 0.024).clamp(8.5, 11.0),
                      fontWeight: FontWeight.w700,
                      color:      entry.methodColor)),
            ),
            SizedBox(width: sw * 0.015),
            Text('#${total - index}',
                style: TextStyle(
                    fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                    color:      _kT4,
                    fontWeight: FontWeight.w500)),
          ]),
          SizedBox(height: sw * 0.01),
          Row(children: [
            Icon(Icons.access_time_rounded,
                size:  (sw * 0.028).clamp(9.5, 12.5), color: _kT4),
            SizedBox(width: sw * 0.008),
            Expanded(
              child: Text(entry.rawDate,
                  style: TextStyle(
                      fontSize:   (sw * 0.027).clamp(9.0, 12.0),
                      color:      _kT4,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ]),
      ),

      // Amount
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(
          '₹${NumberFormat('#,##,###').format(entry.amount)}',
          style: TextStyle(
              fontSize:   (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w900,
              color:      _kT1),
        ),
        SizedBox(height: sw * 0.005),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.016).clamp(5.0, 8.0),
              vertical:   (sw * 0.004).clamp(1.5, 3.5)),
          decoration: BoxDecoration(
              color:        _kGreenBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreenBd, width: 0.5)),
          child: Text('received',
              style: TextStyle(
                  fontSize:   (sw * 0.022).clamp(7.5, 10.0),
                  color:      _kGreen,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    ]),
  );
}